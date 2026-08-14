#!/usr/bin/env python3
"""Fail when production Compose publishes an unexpected or non-loopback port."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


EXPECTED_PORTS = {
    "api": {"published": 8080, "target": 8080},
    "dashboard": {"published": 3000, "target": 3000},
    "guidelines": {"published": 5000, "target": 8080},
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--env-file", required=True, type=Path)
    parser.add_argument("--compose-file", required=True, type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    command = [
        "docker",
        "compose",
        "--env-file",
        str(args.env_file),
        "-f",
        str(args.compose_file),
        "config",
        "--format",
        "json",
    ]
    rendered = subprocess.run(command, check=True, capture_output=True, text=True)
    services = json.loads(rendered.stdout)["services"]
    errors: list[str] = []

    for service_name, service in services.items():
        ports = service.get("ports", [])
        if service_name not in EXPECTED_PORTS:
            if ports:
                errors.append(f"{service_name} unexpectedly publishes {ports!r}")
            continue

        if len(ports) != 1:
            errors.append(f"{service_name} must publish exactly one port, found {ports!r}")
            continue

        port = ports[0]
        if port.get("host_ip") != "127.0.0.1":
            errors.append(
                f"{service_name} must bind to 127.0.0.1, found {port.get('host_ip')!r}"
            )
        expected = EXPECTED_PORTS[service_name]
        if str(port.get("published")) != str(expected["published"]):
            errors.append(
                f"{service_name} publishes {port.get('published')!r}, expected "
                f"{expected['published']}"
            )
        if port.get("target") != expected["target"]:
            errors.append(
                f"{service_name} targets {port.get('target')!r}, expected "
                f"{expected['target']}"
            )
        if port.get("protocol") != "tcp":
            errors.append(f"{service_name} must publish TCP, found {port.get('protocol')!r}")

    if errors:
        print("Production port policy failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        "Production ports are restricted to loopback: "
        "API, dashboard, and guidelines only."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
