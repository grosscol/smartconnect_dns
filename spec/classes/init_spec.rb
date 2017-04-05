require 'spec_helper'
describe 'smartconnect_dns' do
  context 'with default values for all parameters' do
    it { should contain_class('smartconnect_dns') }
  end
end
