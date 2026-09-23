# 🚀 Terraform Day 63 Cheat Sheet: Dynamic Configurations

## 💻 Essential CLI Commands

* **`terraform plan`** : Previews changes using default variables (e.g., `terraform.tfvars`).
* **`terraform plan -var-file="prod.tfvars"`** : Previews changes using a specific environment variable file.
* **`terraform plan -var="instance_type=t2.nano"`** : Overrides all files with a direct inline variable.
* **`terraform output`** : Displays all defined outputs from the state file.
* **`terraform output -json`** : Formats outputs in JSON (ideal for CI/CD pipelines).
* **`terraform console`** : Opens an interactive shell to test functions and expressions without deploying.

## ⚖️ Variable Precedence (Lowest to Highest)

Terraform applies variables in this strict override order:

1. **Environment Variables** (`TF_VAR_environment="prod"`)
2. **`terraform.tfvars`** (Loaded automatically)
3. **`*.auto.tfvars`** (Loaded automatically, processed in alphabetical order)
4. **`-var-file` flag** (`terraform apply -var-file="prod.tfvars"`)
5. **`-var` CLI flag** (`terraform apply -var="env=prod"`) *(Highest Priority)*

## 🧭 Concept Map

| Concept | Keyword | Purpose | Real-World Analogy |
| --- | --- | --- | --- |
| **Variable** | `variable` | Accepts external input to customize the deployment. | Function parameters. |
| **Local** | `locals` | Evaluates an expression once for internal DRY reuse. | Private script variables. |
| **Output** | `output` | Exposes specific resource data to the terminal/other modules. | The `return` statement. |
| **Data Source** | `data` | Fetches read-only information from existing cloud infrastructure. | A `GET` API request. |
| **Resource** | `resource` | Creates, modifies, or destroys cloud infrastructure. | A `POST`/`PUT` API request. |

## 🧩 Variable Types

* **`string`**: `"t3.micro"`
* **`number`**: `80`
* **`bool`**: `true` or `false`
* **`list`**: `["us-east-1a", "us-east-1b"]` *(Ordered sequence, access via index like `var.list[0]`)*
* **`map`**: `{ Environment = "dev", Team = "SRE" }` *(Key-value pairs)*

## 🧮 Expressions & Built-in Functions

**Conditional (Ternary) Expressions:**
Evaluates a condition to determine which value to assign. Format: `condition ? true_value : false_value`

```hcl
instance_type = var.environment == "prod" ? "t3.small" : "t3.micro"

```

**Top 5 Functions for AWS Infrastructure:**

* **`merge(map1, map2)`**: Combines maps. Perfect for standardizing tags.
```hcl
tags = merge(local.common_tags, { Name = "${local.name_prefix}-vpc" })

```


* **`lookup(map, key, default)`**: Safely retrieves a map value, returning a fallback default if the key doesn't exist.
* **`length(list_or_string)`**: Returns the number of items in a list or characters in a string. Crucial for dynamic looping.
* **`join(separator, list)`**: Combines list items into a single string.
```hcl
# join("-", ["web", "prod"]) returns "web-prod"

```


* **`cidrsubnet(prefix, newbits, netnum)`**: Calculates subnet CIDRs mathematically from a base VPC CIDR, eliminating the need to hardcode IP blocks.
