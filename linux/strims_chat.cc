#include "strims_chat.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _StrimsChat {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(StrimsChat, strims_chat, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void strims_chat_activate(GApplication* application) {
  StrimsChat* self = STRIMS_CHAT(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen *screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
     const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
     if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
       use_header_bar = FALSE;
     }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar *header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "strims_chat_mobile");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  }
  else {
    gtk_window_set_title(window, "strims_chat_mobile");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean strims_chat_local_command_line(GApplication* application, gchar ***arguments, int *exit_status) {
  StrimsChat* self = STRIMS_CHAT(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void strims_chat_dispose(GObject *object) {
  StrimsChat* self = STRIMS_CHAT(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(strims_chat_parent_class)->dispose(object);
}

static void strims_chat_class_init(StrimsChatClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = strims_chat_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = strims_chat_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = strims_chat_dispose;
}

static void strims_chat_init(StrimsChat* self) {}

StrimsChat* strims_chat_new() {
  return STRIMS_CHAT(g_object_new(strims_chat_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
