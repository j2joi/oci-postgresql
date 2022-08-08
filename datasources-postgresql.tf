data oci_core_vcn "postgresql_vcn" {
    count = local.create_vcn? 0 : 1
    vcn_id=var.postgresql_vcn     
}

data oci_core_nat_gateways "postgresql_vcn" {
    count = local.create_vcn? 0 : 1
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = var.postgresql_vcn
    filter {
        name   = "state"
        values = ["AVAILABLE"]
    }
}

data "oci_core_subnets" "vcn_subnets" {
    count = local.create_vcn? 0 : 1
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = var.postgresql_vcn
    filter {
        name   = "state"
        values = ["AVAILABLE"]
    }
}
