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

#ifndef _GCAB_CABINET_H_
#define _GCAB_CABINET_H_

#include <gio/gio.h>
#include <glib-object.h>

#include "gcab-folder.h"
#include "gcab-file.h"

G_BEGIN_DECLS

/**
 * GCabCabinet:
 *
 * An opaque object holding a Cabinet file reference.
 **/
#define GCAB_TYPE_CABINET                (gcab_cabinet_get_type ())
G_DECLARE_FINAL_TYPE(GCabCabinet, gcab_cabinet, GCAB, CABINET, GObject)

/**
 * GCAB_ERROR:
 *
 * Error domain for the GCab library. See #GError for more information
 * on error domains.
 */
#define GCAB_ERROR gcab_error_quark ()
GQuark gcab_error_quark (void);

/**
 * GCabError:
 * @GCAB_ERROR_FORMAT:          The given file is not of Cabinet format.
 * @GCAB_ERROR_FAILED:          General function failure.
 * @GCAB_ERROR_NOT_SUPPORTED:   Action or format is not supported
 * @GCAB_ERROR_INVALID_DATA:    Data stream was invalid
 *
 * The various errors triggered by the GCab functions.
 **/
typedef enum GCabError
{
    GCAB_ERROR_FORMAT,
    GCAB_ERROR_FAILED,
    GCAB_ERROR_NOT_SUPPORTED,   /* Since: 1.0 */
    GCAB_ERROR_INVALID_DATA,    /* Since: 1.0 */
} GCabError;

GCabCabinet *      gcab_cabinet_new           (void);
void               gcab_cabinet_add_allowed_compression (GCabCabinet *self,
                                               GCabCompression compression);
gboolean           gcab_cabinet_load          (GCabCabinet *cabinet,
                                               GInputStream *stream,
                                               GCancellable *cancellable,
                                               GError **error);

GPtrArray *        gcab_cabinet_get_folders   (GCabCabinet *cabinet);
guint32            gcab_cabinet_get_size      (GCabCabinet *cabinet);

gboolean           gcab_cabinet_add_folder    (GCabCabinet *cabinet,
                                               GCabFolder *folder,
                                               GError **error);
gboolean           gcab_cabinet_write         (GCabCabinet *cabinet,
                                               GOutputStream *stream,
                                               GCabFileCallback file_callback,
                                               GFileProgressCallback progress_callback,
                                               gpointer user_data,
                                               GCancellable *cancellable,
                                               GError **error);
gboolean           gcab_cabinet_write_simple  (GCabCabinet *cabinet,
                                               GOutputStream *stream,
                                               GCabFileCallback file_callback,
                                               gpointer user_data,
                                               GCancellable *cancellable,
                                               GError **error);
gboolean           gcab_cabinet_extract       (GCabCabinet *cabinet,
                                               GFile *path,
                                               GCabFileCallback file_callback,
                                               GFileProgressCallback progress_callback,
                                               gpointer user_data,
                                               GCancellable *cancellable,
                                               GError **error);
gboolean           gcab_cabinet_extract_simple(GCabCabinet *cabinet,
                                               GFile *path,
                                               GCabFileCallback file_callback,
                                               gpointer user_data,
                                               GCancellable *cancellable,
                                               GError **error);
const GByteArray * gcab_cabinet_get_signature (GCabCabinet *cabinet,
                                               GCancellable *cancellable,
                                               GError **error);

G_END_DECLS

#endif /* _GCAB_CABINET_H_ */
