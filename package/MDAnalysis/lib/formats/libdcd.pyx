# -*- Mode: python; tab-width: 4; indent-tabs-mode:nil; coding:utf-8 -*-
# vim: tabstop=4 expandtab shiftwidth=4 softtabstop=4
#
# MDAnalysis --- http://www.MDAnalysis.org
# Copyright (c) 2006-2015 Naveen Michaud-Agrawal, Elizabeth J. Denning, Oliver
# Beckstein and contributors (see AUTHORS for the full list)
#
# Released under the GNU Public Licence, v2 or any higher version
#
# Please cite your use of MDAnalysis in published work:
#
# N. Michaud-Agrawal, E. J. Denning, T. B. Woolf, and O. Beckstein.
# MDAnalysis: A Toolkit for the Analysis of Molecular Dynamics Simulations.
# J. Comput. Chem. 32 (2011), 2319--2327, doi:10.1002/jcc.21787
#

IF UNAME_SYSNAME == "Windows":
    cdef extern from 'windows.h':
        ctypedef HANDLE fio_fd
        ctypedef LONGLONG fio_size_t;
        ctypedef void * fio_caddr_t;
ELSE:
    from libc.stdio cimport SEEK_SET, SEEK_CUR, SEEK_END, FILE
    ctypedef FILE * fio_fd;
    ctypedef size_t fio_size_t;
    ctypedef void * fio_caddr_t;
    _whence_vals = {"FIO_SEEK_SET": SEEK_SET,
                    "FIO_SEEK_CUR": SEEK_CUR,
                    "FIO_SEEK_END": SEEK_END}

cdef enum:
    FIO_READ = 0x01
    FIO_WRITE = 0x02

cdef extern from 'include/fastio.h':
    ctypedef struct fio_iovec:
        pass

cdef class DCDFile:
    cdef fio_fd fp

    def __cinit__(self, fname, mode='r'):
        self.fname = fname.encode('utf-8')
        self.is_open = False
        self.open(self.fname, mode)


    def __dealloc__(self):
        # call a close_dcd_read
        self.close()

    def open(self, filename, mode):
        # NOTE: to make handling easier lets disallow read/write mode
        if mode == 'r':
            fio_mode = FIO_READ
        elif mode == 'w':
            fio_mode = FIO_WRITE
        else:
            raise IOError("unkown mode '{}', use either r or w".format(mode))
        # ok = fio_open(self.fname, fio_mode, self.fp)
        # if ok != 0:
        #     raise IOError("couldn't open file: {}".format(filename))

    def close(self):
        pass
        # ok = fio_close(self.fp)
        # if ok != 0:
        #     raise IOError("couldn't close file: {}".format(self.fname))
