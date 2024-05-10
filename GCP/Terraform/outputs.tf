output "vm_name_op" {
  value       = {
    for _,v in google_compute_instance.vm_dan : v.name => v.network_interface[0].network_ip
  }
  description = "This will output the VM name"
  }
