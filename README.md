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
     toggle_block: "/bin/bash /config/scripts/toggle_block.sh '{{ target_block }}' '{{ toggle_state }}' '{{ target_file }}' '{{ backup }}'"
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
    - cat
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
    - cat
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
   
This approach allows you to dynamically adjust tracking, filters, zones, camera settings...(anything you can think of), enhancing both functionality and maintainability without having to manually edit the configuration each time or maintain multiple versions of the configuration file.

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
### From Home Assistant Developer Tools

1. **Navigate to Developer Tools**:
   - In Home Assistant, go to the **Developer Tools** section in the left-hand sidebar.

2. **Select the ACTIONS Tab**:
   - Click on the **ACTIONS** tab.
   - Look for the entry called:
     
     ```yaml
     Shell Command: toggle_block
     ```
     
3. **Switch to YAML Mode**:
   - Click the **GO TO YAML MODE** button to switch from the default interface.

4. **Fill in the Parameters**:
   - Paste the following code into the YAML editor and replace values as needed:
     
      ```yaml
     data:
       target_block: home
       toggle_state: "off"
       target_file: frigate.yaml
       backup: "on"
      ```

5. **Perform the Action**:
   - Once you’ve filled in the YAML, click the **PERFORM ACTION** button at the bottom of the page to run the command.

6. **View the Response**:
   - After executing the action, you will receive a response similar to this:

      ```yaml
     stdout: |-
       Backup created: /config/frigate.yaml.bak
       The block 'home' has been commented.
              #<home>
              # - cell phone
              # - wine glass
              #</home>
     stderr: ""
     returncode: 0
      ```

### From Home Assistant Automations

You can easily integrate this script into Home Assistant automations. Here's an example that toggles a block in `frigate.yaml` based on whether the Residents group is home or away:

```yaml
alias: Frigate Toggle Block Home Away
description: >-
  Toggles the home and away blocks of the frigate.yaml configuration file based
  on the state of group.residents
trigger:
  - platform: state
    entity_id:
      - group.residents
    to: away
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
              target_block: home
              toggle_state: "off"
              target_file: frigate.yaml
              backup: "on"
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

### Spacing Requirements: *(It's all about that space!)*

1. **Space after the `#` for toggle blocks**:  
   When toggling comments, the script requires a space after the `#` for it to function properly.  
   - Example: `# max_ratio: 1` will work.  
   - However, `#max_ratio: 1` (without the space) will **not** uncomment the line.

2. **Spacing in tags**:  
   Spaces are only allowed before the `#` in tags.
   - Incorrect: `# <away>`
   - Incorrect: `#<away> ` — can be difficult to spot.
   - Incorrect: `#<away toggle>`

3. **No content after the tag**:  
   There should be nothing after the closing tag.
   - Incorrect: `#<away_toggle> # This is my comment`

### Hard Comments

You can add comments within toggle blocks that will be preserved regardless of the toggle state by removing the space after the `#`. These are called **hard comments** and will not be affected by the script:

```yaml
#<away>
# - person                # This will be toggled
## Hard comment           # This will be preserved and ignored by the script
#</away>
```

### Important Notes

- **Case Sensitivity**: The block markers are case-sensitive. For example, `#<away>` is not the same as `#<Away>`.
- **No nesting**: Tags within tags are not supported. They will be treated as hard comments and will not be toggled. Create a separate toggle block for each tag.
- **Multiplicity**: You can use the same tags in multiple places within a file to keep code maintenance simple. You can use many different tags in a file and they can all be toggled independently.
- **Testing**: It is recommended to copy your target file to a temporary file for testing, 'test.yaml', for example. Always use `show` to verify that your tags and toggle block are being correctly identified before toggling. Use the Home Assistant Developer tools and/or terminal to fully debug before incorporating your toggle block into an automation, where exit errors are often reported as "Action run successfully".
- **More Testing**: Your file still has to be a valid file after all the toggling. If you toggle off a section of the file that is required, and don't toggle on a replacement, you can easily leave the configuration in a non-working state.
- **Backups**: Remember to switch backup to `off` or `no_backup` once you have completed testing and remove any test or .bak files that you no longer need to prevent directory clutter.
- **Last Resort**: This script should be used as a last resort when problems cannot be solved in the "recommended manner". In the case of Home Assistant, be sure you cannot achieve your goal within the GUI before using a heavy handed approach like this. In the specific example of Frigate, many options can be changed from the Home Assistant integration without changing frigate.yaml and restarting Frigate.

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
