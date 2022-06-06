# -*- coding: utf-8 -*-
# ---------------------------------------------------------------------------
# Read Value From Text
# Author: Timm Nawrocki
# Last Updated: 2021-08-19
# Usage: Must be executed in an Anaconda Python 3.8+ distribution.
# Description: "Read Value From Text" is a function that reads a numeric value from a text file.
# ---------------------------------------------------------------------------

# Create a function to read a value from a text file
def read_text_value(input_file):
    """
    Description: reads a value from a text file
    Inputs: 'input_file' -- a text file containing a single numeric value with no formatting
    Returned Value: Returns a value
    Preconditions: requires a text value containing a single numeric value
    """

    # Create a reader
    text_reader = open(input_file, 'r')

    # Read the text value and convert to float
    value = text_reader.readlines()
    text_reader.close()
    output_value = float(value[0])

    # Return output value
    return output_value
