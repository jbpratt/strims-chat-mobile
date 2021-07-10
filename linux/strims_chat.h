#ifndef FLUTTER_STRIMS_CHAT_H_
#define FLUTTER_STRIMS_CHAT_H_

#include <gtk/gtk.h>

G_DECLARE_FINAL_TYPE(StrimsChat, strims_chat, STRIMS, CHAT,
                     GtkApplication)

StrimsChat* strims_chat_new();

#endif  // FLUTTER_STRIMS_CHAT_H_
