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
     toggle_block: >-
       /bin/bash /config/scripts/toggle_block.sh
       "{{ target_block }}"
       "{{ toggle_state }}"
       "{{ target_file }}"
       "{{ backup }}"
    ```
   
4. Restart Home Assistant to apply the changes.

5. Under Developer tools>ACTIONS you will have a new action: `Shell Command: toggle_block`

## Home Assistant path visibility

`toggle_block.sh` can only edit files that are visible to the process running it. When called from Home Assistant `shell_command`, that process is Home Assistant Core, which normally runs with `/config` as its working directory.

That means a file may be visible from Terminal/SSH, Samba, Studio Code Server, or an add-on container, but still not be visible from `shell_command`.

For Home Assistant `shell_command` usage, the safest target path roots are:

- `/config/...`
- `/share/...`

Do not assume that `/addon_configs/...` can be edited directly from `shell_command`. On many Home Assistant OS installations, `/addon_configs` is visible from Terminal/SSH or Samba, but not from the Home Assistant Core container.

### Editing add-on configs from `shell_command`

If you need to edit an add-on config file, such as a Frigate config under `addon_configs`, expose it through a path Home Assistant Core can see.

One practical approach is:

1. Use the Samba Share add-on to expose `addon_configs`.
2. Add `addon_configs` back into Home Assistant as network storage.
3. Set the network storage usage type to `Share`.
4. Use the mounted `/share/...` path in `shell_command`.

Example target paths:

```yaml
/share/addon_configs/ccab4aaf_frigate/config.yaml
```

or, for Frigate Full Access:

```yaml
/share/addon_configs/ccab4aaf_frigate-fa/config.yaml
```

Avoid using SSH into `core-ssh` or another add-on as a bridge from `shell_command`. It depends on add-on hostnames and container details that can change.

## Example: Toggling blocks in Frigate's `config.yaml`

This example demonstrates how the script can toggle blocks in your `config.yaml` configuration file. The script allows you to activate or deactivate specific sections based on conditions (e.g., whether you're home or away).

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
   /bin/bash /config/scripts/toggle_block.sh "away" "show" "config.yaml"
   ```

2. To toggle the `away` block(s) `on` in `config.yaml` with a `backup`:

   ```bash
   /bin/bash /config/scripts/toggle_block.sh "away" "on" "config.yaml" "backup"
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
       target_file: /share/addon_configs/ccab4aaf_frigate/config.yaml
       backup: "on"
      ```

5. **Perform the Action**:
   - Once you’ve filled in the YAML, click the **PERFORM ACTION** button at the bottom of the page to run the command.

6. **View the Response**:
   - After executing the action, you will receive a response similar to this:

      ```yaml
     stdout: |-
       Backup created: /share/addon_configs/ccab4aaf_frigate/config.yaml.bak
       The block 'home' has been commented.
              #<home>
              # - cell phone
              # - wine glass
              #</home>
     stderr: ""
     returncode: 0
      ```

### From Home Assistant Automations

You can easily integrate this script into Home Assistant automations. Here's an example that toggles blocks in Frigate's `config.yaml` based on whether the Residents group is home or away.

This example uses `response_variable` after each edit. Home Assistant may show an automation action as having run even when the shell command returned an error, so checking `returncode`, `stdout`, and `stderr` makes failures visible.

```yaml
alias: Frigate Toggle Block Home Away
description: >-
  Toggles the home and away blocks of the Frigate config.yaml file based on the
  state of group.residents.

  This example assumes the Frigate add-on config folder has been mounted under
  /share/addon_configs so it is visible to Home Assistant shell_command.
triggers:
  - trigger: state
    entity_id:
      - group.residents
    to: not_home
    id: Residents Away
    for:
      hours: 0
      minutes: 1
      seconds: 0
  - trigger: state
    entity_id:
      - group.residents
    to: home
    id: Residents Home
    for:
      hours: 0
      minutes: 0
      seconds: 15
conditions: []
actions:
  - alias: Choose Home or Away Frigate Profile
    choose:
      - alias: Residents Away - Enable Away Blocks and Disable Home Blocks
        conditions:
          - condition: trigger
            id: Residents Away
        sequence:
          - alias: Toggle Home Block Off
            action: shell_command.toggle_block
            data:
              target_block: home
              toggle_state: "off"
              target_file: /share/addon_configs/ccab4aaf_frigate/config.yaml
              backup: "on"
            response_variable: toggle_home_off_result
          - alias: Stop if Home Block Off Failed
            if:
              - alias: Home block off command returned an error
                condition: template
                value_template: "{{ toggle_home_off_result.returncode | int(99) != 0 }}"
            then:
              - alias: Notify Home Block Off Failure
                action: persistent_notification.create
                data:
                  title: Frigate toggle_block failed
                  message: >-
                    Failed while toggling the Frigate home block off.

                    Target file:
                    /share/addon_configs/ccab4aaf_frigate/config.yaml

                    Return code: {{ toggle_home_off_result.returncode }}

                    stdout: {{ toggle_home_off_result.stdout | default("") }}

                    stderr: {{ toggle_home_off_result.stderr | default("") }}
              - alias: Stop Automation After Home Block Off Failure
                stop: toggle_block failed while toggling the home block off
                error: true
          - alias: Wait Before Editing Away Block
            delay:
              seconds: 1
          - alias: Toggle Away Block On
            action: shell_command.toggle_block
            data:
              target_block: away
              toggle_state: "on"
              target_file: /share/addon_configs/ccab4aaf_frigate/config.yaml
              backup: "on"
            response_variable: toggle_away_on_result
          - alias: Stop if Away Block On Failed
            if:
              - alias: Away block on command returned an error
                condition: template
                value_template: "{{ toggle_away_on_result.returncode | int(99) != 0 }}"
            then:
              - alias: Notify Away Block On Failure
                action: persistent_notification.create
                data:
                  title: Frigate toggle_block failed
                  message: >-
                    Failed while toggling the Frigate away block on.

                    The home block was already toggled off, but the away block
                    failed.

                    Target file:
                    /share/addon_configs/ccab4aaf_frigate/config.yaml

                    Return code: {{ toggle_away_on_result.returncode }}

                    stdout: {{ toggle_away_on_result.stdout | default("") }}

                    stderr: {{ toggle_away_on_result.stderr | default("") }}
              - alias: Stop Automation After Away Block On Failure
                stop: toggle_block failed while toggling the away block on
                error: true
      - alias: Residents Home - Enable Home Blocks and Disable Away Blocks
        conditions:
          - condition: trigger
            id: Residents Home
        sequence:
          - alias: Toggle Home Block On
            action: shell_command.toggle_block
            data:
              target_block: home
              toggle_state: "on"
              target_file: /share/addon_configs/ccab4aaf_frigate/config.yaml
              backup: "on"
            response_variable: toggle_home_on_result
          - alias: Stop if Home Block On Failed
            if:
              - alias: Home block on command returned an error
                condition: template
                value_template: "{{ toggle_home_on_result.returncode | int(99) != 0 }}"
            then:
              - alias: Notify Home Block On Failure
                action: persistent_notification.create
                data:
                  title: Frigate toggle_block failed
                  message: >-
                    Failed while toggling the Frigate home block on.

                    Target file:
                    /share/addon_configs/ccab4aaf_frigate/config.yaml

                    Return code: {{ toggle_home_on_result.returncode }}

                    stdout: {{ toggle_home_on_result.stdout | default("") }}

                    stderr: {{ toggle_home_on_result.stderr | default("") }}
              - alias: Stop Automation After Home Block On Failure
                stop: toggle_block failed while toggling the home block on
                error: true
          - alias: Wait Before Editing Away Block
            delay:
              seconds: 1
          - alias: Toggle Away Block Off
            action: shell_command.toggle_block
            data:
              target_block: away
              toggle_state: "off"
              target_file: /share/addon_configs/ccab4aaf_frigate/config.yaml
              backup: "on"
            response_variable: toggle_away_off_result
          - alias: Stop if Away Block Off Failed
            if:
              - alias: Away block off command returned an error
                condition: template
                value_template: "{{ toggle_away_off_result.returncode | int(99) != 0 }}"
            then:
              - alias: Notify Away Block Off Failure
                action: persistent_notification.create
                data:
                  title: Frigate toggle_block failed
                  message: >-
                    Failed while toggling the Frigate away block off.

                    The home block was already toggled on, but the away block
                    failed.

                    Target file:
                    /share/addon_configs/ccab4aaf_frigate/config.yaml

                    Return code: {{ toggle_away_off_result.returncode }}

                    stdout: {{ toggle_away_off_result.stdout | default("") }}

                    stderr: {{ toggle_away_off_result.stderr | default("") }}
              - alias: Stop Automation After Away Block Off Failure
                stop: toggle_block failed while toggling the away block off
                error: true
  - alias: Restart Frigate Add-on After Successful Config Edit
    action: hassio.addon_restart
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
   - Example for files outside `/config`: `/share/addon_configs/ccab4aaf_frigate/config.yaml`
   - Important: When using Home Assistant `shell_command`, the path must be visible from Home Assistant Core. A path that works in Terminal/SSH may not work from `shell_command`.

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

## Troubleshooting

### The file exists in Terminal/SSH, but `toggle_block` fails from `shell_command`

This usually means the file is not visible from the Home Assistant Core container. Test visibility from `shell_command`, not from Terminal/SSH.

Add this temporary diagnostic command to `configuration.yaml`:

```yaml
shell_command:
  debug_toggle_block_paths: >-
    /bin/bash -c '
    echo "PWD=$(pwd)";
    echo "--- /config ---";
    ls -ld /config 2>&1;
    echo "--- /addon_configs ---";
    ls -ld /addon_configs /addon_configs/* 2>&1;
    echo "--- /share ---";
    ls -ld /share /share/* 2>&1;
    '
```

Then run `Shell Command: debug_toggle_block_paths` from Developer Tools > Actions and check the response.

If `/addon_configs` is missing but `/share/addon_configs` exists, use the `/share/...` path as your `target_file`.

### Capture command failures in automations

Use `response_variable` when calling `shell_command.toggle_block`, then check the return code before continuing:

```yaml
- alias: Toggle Example Block
  action: shell_command.toggle_block
  data:
    target_block: example
    toggle_state: "on"
    target_file: /share/addon_configs/ccab4aaf_frigate/config.yaml
    backup: "on"
  response_variable: toggle_result

- alias: Stop if toggle_block Failed
  if:
    - alias: toggle_block command returned an error
      condition: template
      value_template: "{{ toggle_result.returncode | int(99) != 0 }}"
  then:
    - alias: Notify toggle_block Failure
      action: persistent_notification.create
      data:
        title: "toggle_block failed"
        message: >-
          toggle_block failed.

          Return code:
          {{ toggle_result.returncode }}

          stdout:
          {{ toggle_result.stdout | default("") }}

          stderr:
          {{ toggle_result.stderr | default("") }}
    - alias: Stop Automation After toggle_block Failure
      stop: "toggle_block failed"
      error: true
```

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
