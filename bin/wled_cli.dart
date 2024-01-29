import 'dart:io';

import 'package:args/args.dart';
import 'package:wled/wled.dart';

void main(List<String> args) async {
  final opts = parseOptions(args);
  await execMain(opts);
}

Opts parseOptions(List<String> args) {
  final ArgParser argParser = ArgParser();

  final parsed = argParser.parse(args).rest;

  final command = parsed.elementAtOrNull(0)?.trim() ?? '';
  if (command == 'toggle') {
    final IpAddress ip;
    try {
      ip = IpAddress(parsed[1]);
    } on RangeError {
      return OptsError('IP is not provided');
    }

    return OptsToggle(ip);
  } else {
    return OptsError('Unknown command');
  }
}

Future<void> execMain(Opts args) async {
  if (args is OptsError) {
    print("Error: ${args.text}");
    exit(1);
  }

  if (args is OptsAction) {
    final wled = Wled(args.ip.value);
    if (args is OptsToggle) {
      await wled.toggle();
    }
  }

  exit(0);
}

sealed class Opts {}

sealed class OptsSystem extends Opts {}

class OptsError extends OptsSystem {
  final String text;

  OptsError(this.text);
}

sealed class OptsAction extends Opts {
  final IpAddress ip;

  OptsAction(this.ip);
}

class OptsToggle extends OptsAction {
  OptsToggle(IpAddress ip) : super(ip);
}

class IpAddress {
  final String value;

  const IpAddress(this.value);
}
