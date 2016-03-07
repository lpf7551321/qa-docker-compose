#!/usr/bin/python

from jinja2 import Template

import argparse
import os
import sys
import yaml

parser = argparse.ArgumentParser()
parser.add_argument('--config', default='trunk.config', help='config file')
parser.add_argument('input', nargs='*')
args = parser.parse_args()


def parseConfigFromFile(fileName):
  config = yaml.load(open(fileName, 'r'))
  for key in config:
    env = os.getenv(key)
    if env:
      config[key] = env
  return config


def prepareInputOutputPair(inputFiles):
  if len(inputFiles) == 0:
    return {sys.stdin: sys.stdout}
  dict = {}
  for inputFile in inputFiles:
    if inputFile.endswith(".tmpl"):
      outputFile = inputFile[:-5]
    elif inputFile.endswith(".j2"):
      outputFile = inputFile[:-3]
    else:
      sys.stderr.write("Unsupported file: " + inputFile + "\n")
      exit(1)
    sys.stderr.write("Input: " + inputFile + " Output: " +  outputFile + "\n")
    dict[open(inputFile, 'r')] = open(outputFile, 'w')
  return dict


config = parseConfigFromFile(args.config)
sys.stderr.write("Running with config: \n" + str(config) + "\n")

inputOutput = prepareInputOutputPair(args.input)

for inputFile in inputOutput:
  tmpl = Template(inputFile.read())
  inputOutput[inputFile].write(tmpl.render(config))
