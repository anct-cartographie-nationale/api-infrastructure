locals {
  product_information = {
    context : {
      project    = "cartographie-nationale"
      layer      = "infrastructure"
      service    = "api"
      start_date = "2023-09-05"
      end_date   = "unknown"
    }
    purpose : {
      disaster_recovery = "medium"
      service_class     = "bronze"
    }
    organization : {
      client = "anct"
    }
    stakeholders : {
      business_owner  = "celestin.leroux@beta.gouv.fr"
      technical_owner = "marc.gavanier@beta.gouv.fr"
      approver        = "marc.gavanier@beta.gouv.fr"
      creator         = "terraform"
      team            = "cartographie-nationale"
    }
  }
}

locals {
  name_prefix   = "${local.product_information.context.project}-${local.product_information.context.service}"
  project_title = title(replace(local.product_information.context.project, "-", " "))
  layer_title   = title(replace(local.product_information.context.layer, "-", " "))
  service_title = title(replace(local.product_information.context.service, "-", " "))
}
