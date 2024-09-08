# Toggle Block Script for Home Assistant

This script allows you to easily toggle sections of your Home Assistant and Linux configuration files by surrounding them with HTML-like tags. It is especially useful for enabling or disabling sections of your configuration based on specific conditions, such as the state of a group or device. Toggle block improves code maintenance by improving visibility and eliminating the need to maintain multiple configuration files in parallel. 

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

## Example: Toggling blocks in `frigate.yaml`

This example demonstrates how the script can toggle blocks in your `frigate.yaml` configuration file. The script allows you to activate or deactivate specific sections based on conditions (e.g., whether you're home or away).

<table>
  <tr>
    <th>When Home</th>
    <th>When Away</th>
  </tr>
  <tr>
    <td>
       
```yaml
objects:
  track:
    -cat
    #<away>
    # - person
    # - umbrella
    #</away>
    #<home>
    - cell phone
    - wine glass
    #</home>
  filters:
    #<away>
    # person:
      # max_ratio: 1
      # min_area: 100000
    #</away>
```
</td>
<td>
   
```yaml
objects:
  track:
    -cat
    #<away>
    - person
    - umbrella
    #</away>
    #<home>
    # - cell phone
    # - wine glass
    #</home>
  filters:
    #<away>
    person:
      max_ratio: 1
      min_area: 100000
    #</away>
```
</td>
</tr> </table>

### How it works:

1. `cat` is **always** tracked, regardless of the state.
2. The block tagged with `<away>` is active when you're marked as "away" (uncommented) and deactivated when you're "home" (commented). In this case:
   - When away, **`person`** and **`umbrella`** are tracked.
   - Additional filters, such as `max_ratio` and `min_area`, are applied to `person` when away.
3. The block tagged with `<home>` is the opposite, activated only when you're "home". In this case:
   - When home, **`cell phone`** and **`wine glass`** are tracked.
   
This approach allows you to dynamically adjust tracking and filters based on your location, enhancing both functionality and maintainability without having to manually edit the configuration each time.

## Usage

### From the Terminal

You can use the script directly from the terminal by passing the parameters in the following order:

  ```bash
   /bin/bash /config/scripts/toggle_block.sh <target_block> <toggle_state> <target_file> <backup>
  ```

#### Command Line Examples

1. To `show` the `away` block(s) in `frigate.yaml`:
   ```bash
   /bin/bash /config/scripts/toggle_block.sh "away" "show" "frigate.yaml"
   ```

2. To toggle the `away` block(s) `on` in `frigate.yaml` with a `backup`:

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

4. **backup** (Optional): Determines if a backup `.bak` file will be created.
   - `on` or `backup`: Creates a `.bak` file (default).
   - `off` or `no_backup`: Skips backup creation.
   - Note: Backup is skipped automatically for the `show` state.

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
- **No nesting**: Tags within tags are not supported. They will be treated as hard comments and will not be toggled. Create a separate toggle block for each tag.
- **Testing**: It is recommended to copy your target file to a temporary file for testing, 'test.yaml', for example. Always use `show` to verify that your tags and toggle block are being correctly identified before toggling `on`.
- **Multiplicity**: You can use the same tags in multiple places within a file to keep code maintenance simple. You can use multiple different tags in a file and they can be toggled independently.
- **Backups**: Remember to switch backup to `off` or `no_backup` once you have completed testing and remove any test or .bak files that you no longer need.

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
