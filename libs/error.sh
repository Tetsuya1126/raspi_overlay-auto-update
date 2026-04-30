#!/bin/bash
# error handling utilities

die() {
  log_error "$@"
  exit 1
}
