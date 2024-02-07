import 'dart:io';

import 'package:args/args.dart';
import 'package:wled/wled.dart';

const _brightnessStep = 5;

void main(List<String> args) async {
  final opts = parseOptions(args);
  await execMain(opts);
}

Opts parseOptions(List<String> args) {
  final ArgParser argParser = ArgParser();

  final parsed = argParser.parse(args).rest;

  final command = parsed.elementAtOrNull(0)?.trim() ?? '';
  if (command == 'toggle') {
    final IpAddress? ip = _parseIpOrFail(parsed);
    if (ip == null) return OptsError('IP is not provided');

    return OptsToggle(ip);
  } else if (command == 'brightness') {
    final IpAddress? ip = _parseIpOrFail(parsed);
    if (ip == null) return OptsError('IP is not provided');

    final int value;
    try {
      value = int.tryParse(parsed[2]) ?? -1;
    } on RangeError {
      return OptsError('Missing brightness value');
    }
    if (value == -1) return OptsError('Missing brightness value');

    return OptsBrightness(ip, value);
  } else if (command == 'inc_brightness') {
    final IpAddress? ip = _parseIpOrFail(parsed);
    if (ip == null) return OptsError('IP is not provided');

    int? step = null;
    try {
      step = int.tryParse(parsed[2]);
    } on RangeError {}

    return OptsIncBrightness(ip, step);
  } else if (command == 'dec_brightness') {
    final IpAddress? ip = _parseIpOrFail(parsed);
    if (ip == null) return OptsError('IP is not provided');

    int? step = null;
    try {
      step = int.tryParse(parsed[2]);
    } on RangeError {}

    return OptsDecBrightness(ip, step);
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
    } else if (args is OptsBrightness) {
      final newBrightness = args.value.clamp(0, 255);
      await wled.brightness(newBrightness);
    } else if (args is OptsIncBrightness) {
      final step = args.step ?? _brightnessStep;
      final status = await wled.status();
      final newBrightness = (status.brightness + step).clamp(0, 255);
      await wled.brightness(newBrightness);
    } else if (args is OptsDecBrightness) {
      final step = args.step ?? _brightnessStep;
      final status = await wled.status();
      final newBrightness = (status.brightness - step).clamp(0, 255);
      await wled.brightness(newBrightness);
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

class OptsBrightness extends OptsAction {
  final int value;

  OptsBrightness(IpAddress ip, this.value) : super(ip);
}

class OptsIncBrightness extends OptsAction {
  final int? step;

  OptsIncBrightness(IpAddress ip, [this.step]) : super(ip);
}

class OptsDecBrightness extends OptsAction {
  final int? step;

  OptsDecBrightness(IpAddress ip, [this.step]) : super(ip);
}

class IpAddress {
  final String value;

  const IpAddress(this.value);
}

IpAddress? _parseIpOrFail(args) {
  try {
    return IpAddress(args[1]);
  } on RangeError {
    return null;
  }
}
