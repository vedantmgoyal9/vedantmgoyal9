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

#ifndef _GCAB_FOLDER_H_
#define _GCAB_FOLDER_H_

#include <gio/gio.h>
#include <glib-object.h>
#include "gcab-file.h"

G_BEGIN_DECLS

/**
 * GCabFolder:
 *
 * An opaque object, referencing a folder in a Cabinet.
 **/
#define GCAB_TYPE_FOLDER              (gcab_folder_get_type ())
G_DECLARE_FINAL_TYPE(GCabFolder, gcab_folder, GCAB, FOLDER, GObject)

/**
 * GCabCompression:
 * @GCAB_COMPRESSION_NONE: No compression.
 * @GCAB_COMPRESSION_MSZIP: MSZIP compression.
 * @GCAB_COMPRESSION_QUANTUM: QUANTUM compression (unsupported).
 * @GCAB_COMPRESSION_LZX: LZX compression (only decompression supported).
 * @GCAB_COMPRESSION_MASK: compression value mask.
 *
 * Compression used by the #GCabFolder.
 **/
typedef enum
{
    GCAB_COMPRESSION_NONE = 0,
    GCAB_COMPRESSION_MSZIP = 1,
    GCAB_COMPRESSION_QUANTUM = 2,
    GCAB_COMPRESSION_LZX = 3,

    GCAB_COMPRESSION_MASK = 0xf,
} GCabCompression;

GCabFolder *    gcab_folder_new               (gint comptype);
gboolean        gcab_folder_add_file          (GCabFolder *cabfolder,
                                               GCabFile *cabfile,
                                               gboolean recurse,
                                               GCancellable *cancellable,
                                               GError **error);
guint           gcab_folder_get_nfiles        (GCabFolder *cabfolder);
GSList *        gcab_folder_get_files         (GCabFolder *cabfolder);
GCabFile *      gcab_folder_get_file_by_name  (GCabFolder *cabfolder,
                                               const gchar *name);
gint            gcab_folder_get_comptype      (GCabFolder *cabfolder);

G_END_DECLS

#endif /* _GCAB_FILE_H_ */
