# 🚀 Day 38: YAML Basics for CI/CD

> **Part of the Production-Ready DevOps & SRE Journey**  
> *Mastering the core syntax required for pipelines, Kubernetes manifests, and configuration management.*

---

## 📂 Task 1 & 2: `person.yaml`

This file defines basic key-value pairs, standard lists, and inline lists.

```yaml
name: Neeraj
role: Infrastructure Engineer
experience_years: 11
learning: true
tools:
  - Docker
  - Terraform
  - Linux
  - Nginx
  - Git
hobbies: [system_optimization, technical_writing]

```

**📝 SRE Notes on Lists:**
There are two ways to write a list in YAML:

1. **Block Format (Standard):** Uses a hyphen and a space (`- item`) on a new, indented line. Best for readability in long CI/CD pipelines.
2. **Flow Format (Inline):** Uses square brackets and commas (`[item1, item2]`). Best for short arrays like tagging or simple configurations.

---

## 📂 Task 3 & 4: `server.yaml`

This file demonstrates nested objects (dictionaries) and multi-line string handling.

```yaml
server:
  name: sre-prod-web-01
  ip: 10.1.0.55
  port: 443

database:
  host: db.internal.local
  name: telemetry_db
  credentials:
    user: admin
    password: super_secure_password_123

startup_script_block: |
  #!/bin/bash
  echo "Bootstrapping SRE telemetry agent..."
  systemctl enable --now node_exporter
  echo "Node exporter active."

startup_script_folded: >
  This string spans multiple lines in the YAML file 
  for easier reading by engineers, but it will be parsed 
  by the application as a single continuous line separated by spaces.

```

**📝 SRE Notes on Multi-line Strings:**

* **Use `|` (Literal Block):** When you need to preserve exact formatting and newlines. This is heavily used for embedding bash scripts, SSH keys, or inline configuration files.
* **Use `>` (Folded Block):** When you have a massive paragraph or a long command that you want to break into multiple lines for readability in your editor, but the machine needs it executed as one single, long string.

---

## 🔬 Task 5 & 6: Validation & Troubleshooting

**Validating YAML formatting:**

* **The Tab Error:** When intentionally using a `TAB` instead of spaces, parsers immediately throw a fatal error (e.g., `yamllint: syntax error: found character '\t' that cannot start any token`). YAML strictly forbids tabs to prevent cross-editor formatting disasters.
* **Indentation Breakage:** Intentionally shifting a nested key out of alignment results in `mapping values are not allowed here`. YAML relies entirely on visual hierarchy; an unaligned key breaks the dictionary structure.

**Spot the Difference Analysis:**

```yaml
# Block 2 - broken
name: devops
tools:
- docker
  - kubernetes

```

**What is wrong:** The indentation is broken. `- docker` is completely un-indented (sitting at the root level, which confuses the parser since it belongs to `tools:`), while `- kubernetes` is indented. All items in a single block list must share the exact same indentation level.

---

## 💡 3 Key SRE Takeaways

1. **Whitespace is Syntax:** YAML is entirely structural. Exactly 2 spaces per indentation level is the industry standard; a single misaligned space or accidental tab will crash a production CI/CD pipeline.
2. **Boolean Strictness:** `true` / `false` are evaluated as boolean operators. Encasing them in quotes (`"true"`) converts them into basic text strings, which will fail logic checks in tools like Ansible or GitHub Actions.
3. **Quoting Rules:** Strings generally do not require quotes unless they contain reserved YAML characters (like `:`, `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `\`). When in doubt, especially with complex passwords or regex, quote the string.

```

```
