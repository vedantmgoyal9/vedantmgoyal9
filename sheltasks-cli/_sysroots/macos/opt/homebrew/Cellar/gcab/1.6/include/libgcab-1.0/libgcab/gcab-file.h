/*
 * LibGCab
 * Copyright (c) 2012, Marc-André Lureau <marcandre.lureau@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301 USA
 */

#ifndef _GCAB_FILE_H_
#define _GCAB_FILE_H_

#include <gio/gio.h>
#include <glib-object.h>

G_BEGIN_DECLS

/**
 * GCabFile:
 *
 * An opaque object, referencing a file in a Cabinet.
 **/
#define GCAB_TYPE_FILE             (gcab_file_get_type ())
G_DECLARE_FINAL_TYPE(GCabFile, gcab_file, GCAB, FILE, GObject)

/**
 * GCabFileAttribute:
 * @GCAB_FILE_ATTRIBUTE_RDONLY: file is read-only
 * @GCAB_FILE_ATTRIBUTE_HIDDEN: file is hidden
 * @GCAB_FILE_ATTRIBUTE_SYSTEM: file is a system file
 * @GCAB_FILE_ATTRIBUTE_ARCH: file modified since last backup
 * @GCAB_FILE_ATTRIBUTE_EXEC: run after extraction
 * @GCAB_FILE_ATTRIBUTE_NAME_IS_UTF: name contains UTF
 *
 * Attributes associated with the #GCabFile.
 **/
typedef enum
{
  GCAB_FILE_ATTRIBUTE_RDONLY      = 0x01,
  GCAB_FILE_ATTRIBUTE_HIDDEN      = 0x02,
  GCAB_FILE_ATTRIBUTE_SYSTEM      = 0x04,
  GCAB_FILE_ATTRIBUTE_ARCH        = 0x20,
  GCAB_FILE_ATTRIBUTE_EXEC        = 0x40,
  GCAB_FILE_ATTRIBUTE_NAME_IS_UTF = 0x80
} GCabFileAttribute;

/**
 * GCabFileCallback:
 * @file: the file being processed
 * @user_data: user data passed to the callback.
 *
 * The type used for callback called when processing Cabinet archive
 * files.
 **/
typedef gboolean (*GCabFileCallback) (GCabFile *file, gpointer user_data);

GCabFile *      gcab_file_new_with_file             (const gchar *name, GFile *file);
GCabFile *      gcab_file_new_with_bytes            (const gchar *name, GBytes *bytes);
GFile *         gcab_file_get_file                  (GCabFile *file);
GBytes *        gcab_file_get_bytes                 (GCabFile *file);
void            gcab_file_set_bytes                 (GCabFile *file, GBytes *bytes);
const gchar *   gcab_file_get_name                  (GCabFile *file);
guint32         gcab_file_get_size                  (GCabFile *file);
guint32         gcab_file_get_attributes            (GCabFile *file);
const gchar *   gcab_file_get_extract_name          (GCabFile *file);
void            gcab_file_set_extract_name          (GCabFile *file, const gchar *name);
void            gcab_file_set_attributes            (GCabFile *file, guint32 attr);
GDateTime *     gcab_file_get_date_time             (GCabFile *file);
void            gcab_file_set_date_time             (GCabFile *file, GDateTime *dt);

G_GNUC_BEGIN_IGNORE_DEPRECATIONS
G_DEPRECATED_FOR(gcab_file_get_date_time)
gboolean        gcab_file_get_date                  (GCabFile *file, GTimeVal *result);
G_DEPRECATED_FOR(gcab_file_set_date_time)
void            gcab_file_set_date                  (GCabFile *file, const GTimeVal *tv);
G_GNUC_END_IGNORE_DEPRECATIONS

G_END_DECLS

#endif /* _GCAB_FILE_H_ */
