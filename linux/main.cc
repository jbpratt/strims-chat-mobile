#include "strims_chat.h"

int main(int argc, char** argv) {
  g_autoptr(StrimsChat) app = strims_chat_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
