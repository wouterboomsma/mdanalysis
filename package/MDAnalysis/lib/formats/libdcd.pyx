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

from libc.stdio cimport SEEK_SET, SEEK_CUR, SEEK_END
ctypedef int fio_fd;
_whence_vals = {"FIO_SEEK_SET": SEEK_SET,
                "FIO_SEEK_CUR": SEEK_CUR,
                "FIO_SEEK_END": SEEK_END}

cdef enum:
    FIO_READ = 0x01
    FIO_WRITE = 0x02

DCD_ERRORS = {
    0: 'No Problem',
    -1: 'Normal EOF',
    -2: 'DCD file does not exist',
    -3: 'Open of DCD file failed',
    -4: 'read call on DCD file failed',
    -5: 'premature EOF found in DCD file',
    -6: 'format of DCD file is wrong',
    -7: 'output file already exiss',
    -8: 'malloc failed'
}


cdef extern from 'include/fastio.h':
    int fio_open(const char *filename, int mode, fio_fd *fd)
    int fio_fclose(fio_fd fd)
# need to find a typedef for off_t
#    fio_size_t fio_ftell(fio_fd fd)

cdef extern from 'include/readdcd.h':
    int read_dcdheader(fio_fd fd, int *natoms, int *nsets, int *istart,
                       int *nsavc, double *delta, int *nfixed, int **freeind,
                       float **fixedcoords, int *reverse, int *charmm,
                       char **remarks, int *len_remarks)


cdef class DCDFile:
    cdef fio_fd fp
    cdef readonly fname
    cdef int is_open
    cdef int natoms
    cdef int nsets
    cdef int istart
    cdef int nsavc
    cdef double delta
    cdef int nfixed
    cdef int *freeind
    cdef float *fixedcoords
    cdef int reverse
    cdef int charmm
    cdef char *remarks
    cdef int len_remarks

    def __cinit__(self, fname, mode='r'):
        self.fname = fname.encode('utf-8')
        self.is_open = False
        self.open(self.fname, mode)

    def __dealloc__(self):
        self.close()

    def __enter__(self):
        """Support context manager"""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Support context manager"""
        self.close()
        # always propagate exceptions forward
        return False

    def open(self, filename, mode='r'):
        if mode == 'r':
            fio_mode = FIO_READ
        elif mode == 'w':
            fio_mode = FIO_WRITE
        else:
            raise IOError("unkown mode '{}', use either r or w".format(mode))
        ok = fio_open(self.fname, fio_mode, <fio_fd*> &self.fp)
        if ok != 0:
            raise IOError("couldn't open file: {}\n"
                          "ErrorCode: {}".format(self.fname, ok))
        self.is_open = True

    def close(self):
        if self.is_open:
            ok = fio_fclose(self.fp)
            self.is_open = False
            if ok != 0:
                raise IOError("couldn't close file: {}\n"
                            "ErrorCode: {}".format(self.fname, ok))

    def read_header(self):
        if not self.is_open:
            raise RuntimeError("No file open")

        ok = read_dcdheader(self.fp, &self.natoms, &self.nsets, &self.istart,
                            &self.nsavc, &self.delta, &self.nfixed, &self.freeind,
                            &self.fixedcoords, &self.reverse,
                            &self.charmm, &self.remarks, &self.len_remarks)
        if ok != 0:
            raise IOError("Reading DCD header failed: {}".format(DCD_ERRORS[ok]))

        print(self.natoms)
