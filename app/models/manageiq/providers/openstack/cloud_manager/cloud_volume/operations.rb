module ManageIQ::Providers::Openstack::CloudManager::CloudVolume::Operations
  def validate_attach_volume
    validate_volume_available
  end

  def validate_detach_volume
    validate_volume_in_use
  end

  def raw_attach_volume(server_ems_ref, device = nil)
    device = nil if device.try(:empty?)
    with_notification(:cloud_volume_attach,
                      :options => {
                        :subject =>       self,
                        :instance_name => server_ems_ref,
                      }) do
      ext_management_system.with_provider_connection(connection_options) do |service|
        service.servers.get(server_ems_ref).attach_volume(ems_ref, device)
      end
    end
  end

  def raw_detach_volume(server_ems_ref)
    with_notification(:cloud_volume_detach,
                      :options => {
                        :subject =>       self,
                        :instance_name => server_ems_ref,
                      }) do
      ext_management_system.with_provider_connection(connection_options) do |service|
        service.servers.get(server_ems_ref).detach_volume(ems_ref)
      end
    end
  end
end
