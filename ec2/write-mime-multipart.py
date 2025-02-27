#!/usr/bin/env python
# largely taken from python examples
# http://docs.python.org/library/email-examples.html

import os
import sys

from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from optparse import OptionParser
import gzip

COMMASPACE = ', '

starts_with_mappings = {
    '#include': 'text/x-include-url',
    '#include-once': 'text/x-include-once-url',
    '#!': 'text/x-shellscript',
    '#cloud-config': 'text/cloud-config',
    '#cloud-config-archive': 'text/cloud-config-archive',
    '#upstart-job': 'text/upstart-job',
    '#part-handler': 'text/part-handler',
    '#cloud-boothook': 'text/cloud-boothook'
}


def try_decode(data):
    try:
        return (True, data.decode())
    except UnicodeDecodeError:
        return (False, data)


def get_type(fname, deftype):
    rtype = deftype

    with open(fname, "rb") as f:
        (can_be_decoded, line) = try_decode(f.readline())

    if can_be_decoded:
        # slist is sorted longest first
        slist = sorted(list(starts_with_mappings.keys()),
                       key=lambda e: 0 - len(e))
        for sstr in slist:
            if line.startswith(sstr):
                rtype = starts_with_mappings[sstr]
                break
    else:
        rtype = 'application/octet-stream'

    return(rtype)


def main():
    outer = MIMEMultipart()
    parser = OptionParser()

    parser.add_option("-o", "--output", dest="output",
                      help="write output to FILE [default %default]",
                      metavar="FILE", default="-")
    parser.add_option("-z", "--gzip", dest="compress", action="store_true",
                      help="compress output", default=False)
    parser.add_option("-d", "--default", dest="deftype",
                      help="default mime type [default %default]",
                      default="text/plain")
    parser.add_option("--delim", dest="delim",
                      help="delimiter [default %default]", default=":")

    (options, args) = parser.parse_args()

    if (len(args)) < 1:
        parser.error("Must give file list see '--help'")

    for arg in args:
        t = arg.split(options.delim, 1)
        path = t[0]
        if len(t) > 1:
            mtype = t[1]
        else:
            mtype = get_type(path, options.deftype)

        maintype, subtype = mtype.split('/', 1)
        if maintype == 'text':
            fp = open(path)
            # Note: we should handle calculating the charset
            msg = MIMEText(fp.read(), _subtype=subtype)
            fp.close()
        else:
            fp = open(path, 'rb')
            msg = MIMEBase(maintype, subtype)
            msg.set_payload(fp.read())
            fp.close()
            # Encode the payload using Base64
            encoders.encode_base64(msg)

        # Set the filename parameter
        msg.add_header('Content-Disposition', 'attachment',
                       filename=os.path.basename(path))

        outer.attach(msg)

    if options.output == "-":
        if hasattr(sys.stdout, "buffer"):
            # We want to write bytes not strings
            ofile = sys.stdout.buffer
        else:
            ofile = sys.stdout
    else:
        ofile = open(options.output, "wb")

    if options.compress:
        gfile = gzip.GzipFile(fileobj=ofile, filename=options.output)
        gfile.write(outer.as_string().encode())
        gfile.close()
    else:
        ofile.write(outer.as_string().encode())

    ofile.close()

if __name__ == '__main__':
    main()

# vi: ts=4 expandtab
