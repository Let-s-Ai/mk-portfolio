resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-state-bucket-mk-portfolio"
    versioning {
        enabled = true
    }
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
    name           = "terraform-state-lock-table-mk-portfolio"
    hash_key       = "LockID"
    read_capacity  = 1
    write_capacity = 1
    
    attribute {
        name = "LockID"
        type = "S"
    }
    
    billing_mode = "PROVISIONED"
}