class ManageIQ::Providers::Openstack::CloudManager::EventTargetParser
  attr_reader :ems_event

  # @param ems_event [EmsEvent] EmsEvent object to be parsed to derive an object to be refreshed
  def initialize(ems_event)
    @ems_event = ems_event
  end

  # Parses all targets present in the EmsEvent givin in the initializer
  # @return [Array] Array of ManagerRefresh::Target objects
  def parse
    parse_ems_event_targets(ems_event)
  end

  private

  # Parses list of ManagerRefresh::Target(s) out of the given EmsEvent
  #
  # @param ems_event [EmsEvent] EmsEvent object
  # @return [Array] Array of ManagerRefresh::Target objects
  def parse_ems_event_targets(ems_event)
    target_collection = ManagerRefresh::TargetCollection.new(:manager => ems_event.ext_management_system, :event => ems_event)
    if ems_event.event_type.start_with?("compute.instance")
      collect_compute_instance_references!(target_collection, ems_event)
    elsif ems_event.event_type.start_with?("identity.project")
      collect_identity_tenant_references!(target_collection, ems_event)
    elsif ems_event.event_type.start_with?("orchestration.stack")
      collect_orchestration_stack_references!(target_collection, ems_event)
    end

    target_collection.targets
  end

  def parsed_targets(target_collection = {})
    target_collection.select { |_target_class, references| references[:manager_ref].present? }
  end

  def add_target(target_collection, association, ref)
    target_collection.add_target(:association => association, :manager_ref => {:ems_ref => ref})
  end

  def collect_compute_instance_references!(target_collection, ems_event)
    instance_id = ems_event.full_data.fetch_path(:payload, 'instance_id')
    add_target(target_collection, :vms, instance_id) if instance_id
  end

  def collect_identity_tenant_references!(target_collection, ems_event)
    tenant_id = ems_event.full_data.fetch_path(:payload, 'project_id') || ems_event.full_data.fetch_path(:payload, 'initiator', 'project_id')
    add_target(target_collection, :cloud_tenants, tenant_id) if tenant_id
  end

  def collect_orchestration_stack_references!(target_collection, ems_event)
    stack_id = ems_event.full_data.fetch_path(:payload, 'stack_id')
    tenant_id = ems_event.full_data.fetch_path(:payload, 'tenant_id')
    target_collection.add_target(:association => :orchestration_stacks, :manager_ref => {:ems_ref => stack_id}, :options => {:tenant_id => tenant_id})
  end
end
