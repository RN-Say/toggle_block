# Toggle Block Script for Home Assistant

This script allows you to easily toggle blocks of code in your Home Assistant and Linux configuration files by surrounding them with HTML-like tags. It is especially useful for enabling or disabling sections of your configuration based on specific conditions, such as the state of a group or device.

## Installation

1. Download the `toggle_block.sh` script and place it in your Home Assistant configuration directory (e.g., `/config/scripts`).

2. Access the terminal and make the script executable:
   
   ```bash
   chmod +x /config/scripts/toggle_block.sh
   ```
   
3. Add the following to your `configuration.yaml` to make the script available for use in Home Assistant automations:
   
    ```yaml
    shell_command:
      toggle_block: /bin/bash /config/scripts/toggle_block.sh
    ```
   
4. Restart Home Assistant to apply the changes.

5. Under Developer tools>ACTIONS you will have a new action: `Shell Command: toggle_block`

## Parameters

The script accepts four parameters in the following order:

1. **target_block** (Required): The name of the block you want to toggle. Blocks that need toggling should be surrounded by case-sensitive HTML-like tags.
   - Example: `#<away>` and `#</away>`.

2. **toggle_state** (Required): The desired state of the block, either `on`, `off` or `show`.
   - `on` will uncomment the block.
   - `off` will comment the block.
   - `show` will display the block without making changes.

3. **target_file** (Required): The YAML file where the block is located. If a file name is provided without a path, the script assumes it is in the `/config` directory.
   - Example: `frigate.yaml` will be treated as `/config/frigate.yaml`.

4. **backup** (Optional): Specifies whether to create a backup of the file. Accepts:
   - `on` or `backup`: Creates a `.bak` file.
   - `off` or `no_backup`: Skips backup creation.
   - Backup creation is skipped for toggle_state `show`
   - If not provided for toggle_state `on` or `off`, defaults to creating a backup.

## Usage

### From the Terminal

You can use the script directly from the terminal by passing the parameters in the following order:

  ```bash
   /bin/bash /config/scripts/toggle_block.sh <target_block> <toggle_state> <target_file> <backup>
  ```

#### Example Command

To toggle the `away` block `on` in `frigate.yaml` with a `backup`:

  ```bash
   /bin/bash /config/scripts/toggle_block.sh "away" "on" "frigate.yaml" "backup"
  ```

### From Home Assistant Automations

You can easily integrate this script into Home Assistant automations. Here's an example that toggles a block in `frigate.yaml` based on whether the Residents group is home or away:

```yaml
alias: Frigate toggle_block
description: "Toggle configuration settings in frigate.yaml based on the state of the Residents group"
trigger:
  - platform: state
    entity_id:
      - group.residents
    to: Away
    id: Residents Away
  - platform: state
    entity_id:
      - group.residents
    to: home
    id: Residents Home
condition: []
action:
  - choose:
      - conditions:
          - condition: trigger
            id:
              - Residents Away
        sequence:
          - action: shell_command.toggle_block
            data:
              target_block: away
              toggle_state: "on"
              target_file: frigate.yaml
              backup: "on"
      - conditions:
          - condition: trigger
            id:
              - Residents Home
        sequence:
          - action: shell_command.toggle_block
            data:
              target_block: away
              toggle_state: "off"
              target_file: frigate.yaml
              backup: "on"
  - action: hassio.addon_start
    data:
      addon: ccab4aaf_frigate
mode: single
```

### Hard Comments

You can add comments within blocks that will be preserved regardless of the toggle state by removing the space after the `#`. These are called **hard comments** and will not be affected by the script:

```yaml
#<away>
# - person                # This will be toggled
## Hard comment           # This will be preserved and ignored by the script
#</away>
```

### Important Notes

- **Case Sensitivity**: The block markers are case-sensitive. For example, `#<away>` is not the same as `#<Away>`.
- **Spacing Requirement**: The script requires a space after the `#` for it to properly toggle comments. If the space is missing (`#-person`), the script will not uncomment the line.
- **Testing**: It is recommended to copy your target file to a temporary file for testing, 'test.yaml', for example.
- **Multiplicity**: You can use the same tags in as many places as you need to within a file to keep code maintenance simple. You can use multiple different tags in a file that can be toggled independently.

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
