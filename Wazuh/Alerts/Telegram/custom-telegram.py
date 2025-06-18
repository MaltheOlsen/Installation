#!/usr/bin/env python

import sys
import json
import requests
from requests.auth import HTTPBasicAuth

# --- Configuration ---
# Telegram Chat ID: Replace with your actual Telegram Chat ID
# You can get your chat ID by sending a message to your bot and then
# visiting https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
CHAT_ID="5342483256"

# --- Helper Functions ---

# Function to sanitize log content for MarkdownV2 code blocks.
# This prevents '```' within the log from prematurely closing the Markdown code block
# in the Telegram message, which could also lead to Python syntax errors if not handled.
def sanitize_for_markdown_code_block(text):
    # Ensure all newlines are Unix-style for consistency
    text = text.replace('\r\n', '\n').replace('\r', '\n')
    # Replace '```' with '`\``'. This renders as three backticks but breaks the Markdown parsing pattern,
    # preventing it from being interpreted as a closing code block delimiter.
    # It also prevents Python's f-string from misinterpreting `"""` if present in the log.
    text = text.replace('```', '`\\``')
    return text

# Function to escape MarkdownV2 special characters for general text that is NOT within code blocks.
# Telegram's MarkdownV2 requires certain characters to be escaped if they appear literally
# and are not intended for formatting.
def escape_markdown_v2_text(text):
    # The backslash itself must be escaped first if it's a literal character
    text = text.replace('\\', '\\\\')
    # List of characters that need to be escaped in MarkdownV2.
    # Order matters for some overlapping characters (e.g., backticks and underscores).
    # We include '`' here, but for fields going into `...` or ```...```, this particular
    # escaping is not needed for the content *within* those blocks.
    # For literal '!', it *must* be escaped.
    special_chars = [
        '_', '*', '[', ']', '(', ')', '~', '>', '#',
        '+', '-', '=', '|', '{', '}', '.', '!'
    ]
    for char in special_chars:
        text = text.replace(char, f'\\{char}')
    return text

# --- Main Script Logic ---
if __name__ == "__main__":
    # Wazuh passes alert file path as sys.argv[1] and other args.
    # Your ossec.conf should pass the Telegram API URL as sys.argv[3].
    if len(sys.argv) < 4:
        print("Usage: custom-telegram.py <alert_file> <active_response_name> <telegram_api_url>", file=sys.stderr)
        sys.exit(1)

    alert_file_path = sys.argv[1]
    # sys.argv[2] is typically the active response name (e.g., "telegram-alert"), not used directly here.
    hook_url = sys.argv[3] # This should be "[https://api.telegram.org/bot](https://api.telegram.org/bot)<YOUR_BOT_TOKEN>/sendMessage"

    # Read and parse the alert JSON file provided by Wazuh
    try:
        with open(alert_file_path, 'r') as f:
            alert_json = json.loads(f.read())
    except FileNotFoundError:
        print(f"Error: Alert file not found at {alert_file_path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON from alert file {alert_file_path}: {e}", file=sys.stderr)
        sys.exit(1)

    # --- Extract and Sanitize Data Fields ---
    # Extract data using .get() for safer access, providing "N/A" as default if missing.
    # Convert to string to ensure consistent handling during formatting.
    rule_id = str(alert_json.get('rule', {}).get('id', "N/A"))
    alert_level = str(alert_json.get('rule', {}).get('level', "N/A"))
    description = str(alert_json.get('rule', {}).get('description', "N/A"))
    agent_name = str(alert_json.get('agent', {}).get('name', "N/A"))
    agent_id = str(alert_json.get('agent', {}).get('id', "N/A"))
    full_log_raw = str(alert_json.get('full_log', "N/A"))
    location = str(alert_json.get('location', "N/A"))
    timestamp = str(alert_json.get('timestamp', "N/A"))

    # Apply sanitization for fields that go into MarkdownV2 formatting.
    # full_log needs special handling for code blocks.
    sanitized_full_log = sanitize_for_markdown_code_block(full_log_raw)

    # For the header line which is outside backticks, we manually escape the '!'
    alert_header_text = "*Wazuh Alert\\!*" # Explicitly escape '!'

    # --- Construct Telegram Message ---
    msg_data = {}
    msg_data['chat_id'] = CHAT_ID

    # Use an f-string for easy formatting.
    # Ensure all parts that are not explicitly Markdown formatting (like `*` for bold)
    # are either wrapped in backticks or escaped if they contain Markdown special characters.
    message_text = f"""
{alert_header_text}

*Timestamp:* `{timestamp}`
*Rule ID:* `{rule_id}`
*Level:* `{alert_level}`
*Description:* `{description}`
*Agent Name:* `{agent_name}` \(ID: `{agent_id}`\)
*Location:* `{location}`

*Full Log:*
{sanitized_full_log}

""" 

    msg_data['text'] = message_text
    msg_data['parse_mode'] = 'MarkdownV2' # Specify MarkdownV2 parsing mode

    headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}

    # --- Send the Telegram Request ---
    try:
        response = requests.post(hook_url, headers=headers, data=json.dumps(msg_data))
        response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)
        print(f"Telegram message sent successfully! Response: {response.json()}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending Telegram message: {e}", file=sys.stderr)
        if hasattr(e, 'response') and e.response is not None:
            print(f"Telegram API Response (Error): {e.response.text}", file=sys.stderr)
        sys.exit(1) # Exit with an error code if sending fails

    sys.exit(0) # Exit successfully
