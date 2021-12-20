import sys
import argparse
import os
import unittest

def bytes_to_utf8(in_filename, out_filename):
  """
  Read the input file bytes and write it to the output file as
  utf8 dropping invalid bytes.
  """
  # Read the input file into memory as bytes.
  if not os.path.exists(in_filename):
    print("File is missing: %s" % in_filename)
    return 0
  with open(in_filename, "rb") as fh:
    fileData = fh.read()
  # fileData type: <class 'bytes'>
  # print("fileData type: " + str(type(fileData)))

  # Decode the bytes as utf8 to produce a utf8 string. Drop the
  # invalid bytes.
  string = fileData.decode("utf-8", 'ignore')
  # string type: <class 'str'>
  # print("string type: " + str(type(string)))

  # Write the string to the output file.
  with open(out_filename, "w") as fh:
    fh.write(string)

def parse_command_line(argv):
  """
  Parse the command line and return an object that has the
  parameters as attributes.
  """
  parser = argparse.ArgumentParser(description="""\
Read an input file and write it to a utf8 output file dropping invalid
bytes.
""")
  parser.add_argument("in_filename", type=str,
                        help="the input file",
                        default=None)
  parser.add_argument("out_filename", type=str,
                        help="the output file",
                        default=None)
  args = parser.parse_args(argv[1:])
  return args

  args = parse_command_line(sys.argv)

def create_file(filename, content):
  fh = open(filename, 'wb')
  fh.write(content)
  fh.close()

def test_bytes_to_utf8(in_bytes, expected_bytes):
  """
  Return True when the bytes_to_utf8 with in_bytes results in the
  expected bytes.
  """
  in_filename = "in_temp.txt"
  create_file(in_filename, in_bytes)

  out_filename = "out_temp.txt"
  bytes_to_utf8(in_filename, out_filename)

  rc = True
  if not os.path.exists(out_filename):
    print("out_filename was not created.")
    rc = False

  with open(out_filename, "rb") as fh:
    fileData = fh.read()

  if fileData != expected_bytes:
    rc = False

  os.remove(in_filename)
  os.remove(out_filename)
  return rc

class TestBytesToUtf8(unittest.TestCase):
  def test_me(self):
    self.assertEqual(1, 1)

  def test_bytes_to_utf8(self):
    self.assertTrue(test_bytes_to_utf8(b"abc", b"abc"))

  def test_1(self):
    with open("test.txt", "wb") as fh:
      fh.write(b'\xC2\xA9')
    os.remove("test.txt")

  def test_2(self):
    input_bytes = b'\xC2\xA9'
    self.assertTrue(test_bytes_to_utf8(input_bytes, input_bytes))

  def test_3(self):
    # invalid hex at 3: (123 ef 80): 31 32 33 ef 80
    input_bytes = b'\x31\x32\x33\xef\x80'
    expected = b'\x31\x32\x33'
    self.assertTrue(test_bytes_to_utf8(input_bytes, expected))

  def test_overlong_slash(self):
    # invalid hex at 0: (overlong slash c0 af): c0 af
    input_bytes = b'\xc0\xaf'
    expected = b''
    self.assertTrue(test_bytes_to_utf8(input_bytes, expected))

if __name__ == "__main__":
  if sys.version_info < (3, 0):
    print("This program requires python 3 or above.")
    sys.exit(1)

  if 1:
    args = parse_command_line(sys.argv)
    bytes_to_utf8(args.in_filename, args.out_filename)
  else:
    unittest.main()
