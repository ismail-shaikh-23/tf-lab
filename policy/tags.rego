package main

import rego.v1

required_tags := {"owner", "env"}

deny contains msg if {
  some name, res in input.resource.aws_instance
  tags := object.get(res, "tags", {})
  present := {k | some k, _ in tags}
  missing := required_tags - present
  count(missing) > 0
  msg := sprintf("aws_instance.%s missing tags: %v", [name, missing])
}
