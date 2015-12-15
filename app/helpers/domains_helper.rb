module DomainsHelper

  # Human names for domain states
  def human_state(state)
    case state.to_sym
    when :initial then 'Initial'
    when :pending_install then 'Becoming public'
    when :pending_signing then 'Signing zone'
    when :wait_for_ready then 'Waiting for KSK to become ready'
    when :pending_ds then 'Publishing DS records'
    when :pending_plain then 'Removing dnssec'
    when :pending_remove then 'Preparing removal'
    when :operational then 'Operational'
    when :destroy then 'Ready to be destroyed'
    else
      state
    end
  end
end
