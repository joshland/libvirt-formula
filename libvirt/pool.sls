{% set cfg_libvirt = salt['pillar.get']('libvirt', {}) %}
{% set cfg_pools   = cfg_libvirt.get('dirpools', {})     %}
{% set tmpl_path   = "/etc/lvsettings"               %}

{{ tmpl_path }}:
  file.directory:
    - dir_mode:  '0755'
    - file_mode: '0664'
    - user:      root
    - group:     root

/tmp/malfea:
  file.managed:
    - mode: '0644'
    - user: root
    - group: root
    - contents: |
        {{ cfg_libvirt }}
        {{ cfg_pools }}
        {{ tmpl_path }}

{% for pool, values in cfg_pools.items() %}
dirpool {{ pool }}:
  file.directory:
    - name: {{ values['path'] }}
    - dir_mode: '0755'
    - file_mode: '0644'
    - user: root
    - group: root

{{  tmpl_path }}/{{ pool }}:
  file.managed:
    - user:  root
    - group: root
    - mode: '0644'
    - contents: |
        <pool type='dir'>
          <name>{{ pool }}</name>
          <target>
            <path>{{ values['path'] }}</path>
            <permissions>
            <mode>0755</mode>
            <owner>0</owner>
            <group>0</group>
            </permissions>
          </target>
        </pool> 
  cmd.run:
    - name: virsh pool-define {{  tmpl_path }}/{{ pool }} && virsh pool-start {{ pool }}
    - unless: test -f /etc/libvirt/storage/{{ pool }}.xml
{% endfor %}
