# encoding: UTF-8
#
# Copyright 2014, Christoph Hartmann
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'jenkins-hardening::proxy' do

  # converge
  cached(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.automatic['root_group'] = 'root'
    end.converge(described_recipe)
  end

  before do
    stub_command('which nginx').and_return(true)
    stub_data_bag_item('jenkins', 'ssl').and_return(
      id: 'ssl',
      server: {
        key: '-----BEGIN RSA PRIVATE KEY-----\nSERVERaabbcc=\n-----END RSA PRIVATE KEY-----\n',
        cert: '-----BEGIN CERTIFICATE-----\nSERVERaabbcc=\n-----END CERTIFICATE-----\n',
        cacert: '-----BEGIN CERTIFICATE-----\nSERVERaabbcc==\n-----END CERTIFICATE-----\n'
      },
      client: {
        key: '-----BEGIN RSA PRIVATE KEY-----\nCLIENTaabbcc=\n-----END RSA PRIVATE KEY-----\n',
        cert: '-----BEGIN CERTIFICATE-----\nCLIENTaabbcc==\n-----END CERTIFICATE-----\n'
      })
  end

  it 'includes nginx recipe' do
    expect(chef_run).to include_recipe('nginx::default')
  end

  it 'creates the jenkins cert with the correct attributes' do
    expect(chef_run).to create_file('/etc/nginx/conf.d/jenkins.cert').with(
        owner: 'root',
        group: 'root',
        mode:  '0644'
    )
  end

  it 'the jenkins cert has the correct content' do
    expect(chef_run).to render_file('/etc/nginx/conf.d/jenkins.cert')
      .with_content(/BEGIN CERTIFICATE-----\\nCLIENT/)
  end

  it 'creates the jenkins key with the correct attributes' do
    expect(chef_run).to create_file('/etc/nginx/conf.d/jenkins.key').with(
        owner: 'root',
        group: 'root',
        mode:  '0600'
    )
  end

  it 'the jenkins key has the correct content' do
    expect(chef_run).to render_file('/etc/nginx/conf.d/jenkins.key')
      .with_content(/BEGIN RSA PRIVATE KEY-----\\nCLIENT/)
  end

  it 'creates the jenkins site template with the correct attributes' do
    expect(chef_run).to create_template('/etc/nginx/conf.d/jenkins.conf').with(
        owner: 'root',
        group: 'root',
        mode:  '0644'
    )
  end

  it 'the jenkins site template has the correct content' do
    expect(chef_run).to render_file('/etc/nginx/conf.d/jenkins.conf')
      .with_content(/ssl_prefer_server_ciphers/)
  end
end
