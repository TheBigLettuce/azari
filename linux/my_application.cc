// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation; version 2. This program is distributed in the hope that it will
// be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
// Public License for more details. You should have received a copy of the GNU
// General Public License along with this program; if not, write to the Free
// Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
// 02110-1301, USA.

#include "my_application.h"
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <flutter_linux/flutter_linux.h>
#include <libgen.h>
#include <linux/limits.h>
#include <string.h>
#include <sys/types.h>
#include <type_traits>

#include <unistd.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char **dart_entrypoint_arguments;
  FlMethodChannel *fullscreen_channel;
  static bool *in_fullscreen;
  static GtkWindow *window;

public:
  static FlMethodResponse *set_title(const gchar *title) {
    gtk_window_set_title(window, title);

    return FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
  }

  static FlMethodResponse *unset_title() {
    gtk_window_set_title(window, "Ācārya");

    return FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
  }

  static FlMethodResponse *go_fullscreen() {
    if (*in_fullscreen == FALSE) {
      gtk_window_fullscreen(window);
    } else {
      gtk_window_unfullscreen(window);
    }

    return FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
  }

  static gboolean set_in_fullscreen(GtkWidget *widget, GdkEvent *event,
                                    gpointer user_data) {
    GdkEventWindowState wstate = event->window_state;
    GdkWindowState state = gdk_window_get_state(wstate.window);

    *in_fullscreen = state & GDK_WINDOW_STATE_FULLSCREEN;

    return FALSE;
  }

  static FlMethodResponse *fullscreen_untoggle() {
    gtk_window_unfullscreen(window);

    return FL_METHOD_RESPONSE(fl_method_success_response_new(NULL));
  }

  static void fullscreen_method_call_handler(FlMethodChannel *channel,
                                             FlMethodCall *method_call,
                                             gpointer user_data) {
    g_autoptr(FlMethodResponse) response = nullptr;
    if (strcmp(fl_method_call_get_name(method_call), "fullscreen") == 0) {
      response = go_fullscreen();
    } else if (strcmp(fl_method_call_get_name(method_call),
                      "fullscreen_untoggle") == 0) {
      response = fullscreen_untoggle();
    } else if (strcmp(fl_method_call_get_name(method_call), "default_title") ==
               0) {
      response = unset_title();
    } else if (strcmp(fl_method_call_get_name(method_call), "set_title") == 0) {
      FlValue *value = fl_method_call_get_args(method_call);

      response = set_title(fl_value_get_string(value));
    } else {
      response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    }

    g_autoptr(GError) error = nullptr;
    if (!fl_method_call_respond(method_call, response, &error)) {
      g_warning("Failed to send response: %s", error->message);
    }
  }
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)
bool *_MyApplication::in_fullscreen;
GtkWindow *_MyApplication::window;

// Implements GApplication::activate.
static void my_application_activate(GApplication *application) {
  MyApplication *self = MY_APPLICATION(application);
  GtkWindow *window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  self->window = window;

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
    const gchar *wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar *header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Ācārya");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Ācārya");
  }

  char res[PATH_MAX];
  ssize_t count = readlink("/proc/self/exe", res, PATH_MAX);
  g_assert(count);

  char *dir = dirname(res);

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  char *newString;

  asprintf(&newString, "%s%s", dir, "/icon.png");

  gtk_window_set_icon_from_file(window, newString,
                                NULL); // AppDir image

  // free(dir);
  free(newString);

  g_signal_connect(G_OBJECT(window), "window-state-event",
                   G_CALLBACK(self->set_in_fullscreen), NULL);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView *view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->fullscreen_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "lol.bruh19.azari.gallery", FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      self->fullscreen_channel, self->fullscreen_method_call_handler, self,
      nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication *application,
                                                  gchar ***arguments,
                                                  int *exit_status) {
  MyApplication *self = MY_APPLICATION(application);
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
static void my_application_dispose(GObject *object) {
  MyApplication *self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->fullscreen_channel);
  g_clear_object(&self->in_fullscreen);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass *klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication *self) {
  self->in_fullscreen = new bool(FALSE);
}

MyApplication *my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
