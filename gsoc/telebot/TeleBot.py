#!/usr/bin/env python3

import json
import asyncio
from datetime import datetime
import re
import pandas as pd
from telethon import TelegramClient
from telethon.errors import SessionPasswordNeededError
from telethon.tl.functions.messages import (GetHistoryRequest)
from google.cloud import storage, bigquery

with open("config.json", "r") as jsonfile:
    config = json.load(jsonfile)
api_id = config['Telegram']['api_id']
api_hash = config['Telegram']['api_hash']
api_hash = str(api_hash)
phone = config['Telegram']['phone']
username = config['Telegram']['username']
client = TelegramClient(username, api_id, api_hash)
current_time = datetime.now()
formatted_time = current_time.strftime("%Y%m%d%H%M")

# GCS details
bucket_name = 'govilbi_files'
gcs_dir = 'gsoc/telebot'
# BQ details
BIGQUERY_CLIENT = bigquery.Client()
DEST_TABLE_ID = f'GovilBiRepDS.MRR_Gsoc_Telebot_Tested_Ids'

messages_keys = ['digital.gov.il', 'gov.il', 'gov[.]il', '.il', '[.]il', 'israhell', 'opisrael']
messages_values = [10, 9, 9, 7, 7, 5, 4]
messages_words = [{'key': messages_keys[i], 'value': messages_values[i]} for i in range(len(messages_keys))]

files_keys = ['digital.gov.il', 'gov[.]il', 'gov.il', '.il', '[.]il', 'opisrael', 'israel', 'israhell']
files_values = [10, 9, 9, 7, 7, 7, 7, 7]
files_words = [{'key': files_keys[i], 'value': files_values[i]} for i in range(len(files_keys))]

ListOfBigVolumeChannel = ['breachdetector']
ListOfChannels = ['OfficialGhostClan', 'lcmysecteamch', 'ganosecteam', 'TYG_YE', 'teaminsanepk', 'x1915x',
                  'AnonGhostOfficialTeam', 'GhostSecc',
                  'eaglecyberwashere', 'barbbyofficial', 'dragonforceio', 'Exploitationn', 'MysteriousTeam0',
                  'ANONYMOUS_KGT',
                  'ForceElectronicQuds01', 'ALtahrea', 'black_reward', 'JerusalemElectronicArmy', 'BFrepo',
                  'AnonCyberVn',
                  'malaysiadefacers', 'ifc_team', 'team1919', 'HOSTKILL', 'meadowapi',
                  'SQLITE_CHALL_CH355',
                  'jambicyberteam', 'MinionsCyberCrimeHacktivist', 'TheHackerCommunity', 'islamic_Hacker_Army',
                  'eightbase', 'AnonGhostid', 'D4LGH4CK_TM', 'turkhckteam', 'AnonymousSchweizOrginal', 'AnonymousSudan',
                  'pakistancyberhunters', 'q_1xx', 'cents4life', 'babatatasasa', 'weareaig', 'TigerElectronicUnit',
                  'BLOODYSECC', 'SANGKANCIL_LEAK_ISRAEL_SAPIR2', 'ALTOUFANTEAM', 'FRS3C', 'AnonGhostDataLeaked',
                  'FRE3SEC', 'vulzsec_team', 'FREES3C', 'sharpboys_3', 'sharpboys_5', 'HOS_group', 'AnonOperation',
                  'ghostsecc_its_gov', 'GiantsPalestine', 'opsbedil', 'MuslimCyberArmyMY', 'Tigercyberteamwashere',
                  'panoc_team', 'Devils_Sec', 'stucxnet', 'GhostClanOfficial', 'qofnericw1', 'v19crewchannel',
                  'KEP_TEAM',
                  'BlackPirates1', 'SynixCyberCrimeMy', 'EAGLECYBER999', 'ANONYMOUSINDONESIA2']

# failed_channels = ['AnonymousGE']

alert_found_key_word = []
ids_to_load = []


def gcs_json_file_gen():
    alerts_found = alert_found_key_word

    # generate a json file of the suspected messages if there are, and load to gcs bucket
    if alert_found_key_word:
        output_filename = f'telebot_gsoc.json'
        with open(output_filename, 'w') as json_file:
            json.dump(alert_found_key_word, json_file, indent=4)

        storage_client = storage.Client()
        bucket = storage_client.get_bucket(bucket_name)
        destination = f"{gcs_dir}/{output_filename}"
        new_blob = bucket.blob(destination)
        new_blob.upload_from_filename(output_filename)
        metadata = {"project": "gsoc", "subproject": "telebot"}
        new_blob.metadata = None
        new_blob.patch()
        new_blob.metadata = metadata
        new_blob.patch()
        print("JSON file successfully uploaded to GCS!")
    else:
        print("No data found. Skipping file creation.")


def upload_new_ids(data):
    job_config = bigquery.LoadJobConfig(autodetect=True)  # change definition
    print(f'Loading data to {DEST_TABLE_ID} ...')
    job = BIGQUERY_CLIENT.load_table_from_dataframe(data, DEST_TABLE_ID, job_config=job_config)
    if job.result():
        print(f'Load process has been successfully completed '
              f'with {data.iloc[:, 0].size} new rows')


def CheckMsg(group, full_message, cleared_message):
    if full_message['message_content'] or full_message['file_name']:
        # case: null message + file OR no message but only a file
        if full_message['message_content'] == '':
            for pair in files_words:
                check_msg = re.sub(r"[^a-zA-Z0-9\s.]", "", full_message['file_name'])
                if pair['key'] in check_msg.lower():
                    link = f"https://t.me/{group}/{full_message['message_id']}"
                    alert_found_key_word.append({"GroupName": group,
                                                 "KeyWord": pair['key'],
                                                 "Message": re.sub(r'#\w+\n', '', full_message['file_name']),
                                                 "Date": full_message['message_date'],
                                                 "Link": link,
                                                 "Severity": pair['value']})
                    return
        # case: full message + file OR only message but no file
        else:
            for pair in messages_words:
                # case message contains suspected words
                if pair['key'] in cleared_message:
                    link = f"https://t.me/{group}/{full_message['message_id']}"
                    alert_found_key_word.append({"GroupName": group,
                                                 "KeyWord": pair['key'],
                                                 "Message": re.sub(r'#\w+\n', '', full_message['message_content']),
                                                 "Date": full_message['message_date'],
                                                 "Link": link,
                                                 "Severity": pair['value']})
                    return
                else:
                    if full_message['file_name']:
                        check_msg = re.sub(r"[^a-zA-Z0-9\s.]", "", full_message['file_name'])
                        for pair1 in files_words:
                            if pair1['key'] in check_msg.lower():
                                link = f"https://t.me/{group}/{full_message['message_id']}"
                                alert_found_key_word.append({"GroupName": group,
                                                             "KeyWord": pair1['key'],
                                                             "Message": re.sub(r'#\w+\n', '',
                                                                               full_message['file_name']),
                                                             "Date": full_message['message_date'],
                                                             "Link": link,
                                                             "Severity": pair1['value']})
                                return


def isFileNameExist(obj):
    if 'media' in obj.keys() and obj['media']:
        if 'document' in obj['media'].keys() and obj['media']['document']:
            if 'attributes' in obj['media']['document'].keys() and obj['media']['document']['attributes']:
                if obj['media']['document']['attributes'][0]:
                    if 'file_name' in obj['media']['document']['attributes'][0].keys() \
                            and obj['media']['document']['attributes'][0]['file_name']:
                        return True
    return False


# extracts the highest date value from a given table
def get_exist_ids(id_field):
    query_str = f"select distinct {id_field} from `{BIGQUERY_CLIENT.project}.{DEST_TABLE_ID}` order by {id_field}"
    query_job = BIGQUERY_CLIENT.query(query_str).to_dataframe()
    return list(query_job[f'{id_field}'])


# checks either table exist in the DB or not
def is_tbl_exist(table_id):
    dataset_ref = bigquery.dataset.DatasetReference(BIGQUERY_CLIENT.project, table_id.split('.')[0])
    table_ref = bigquery.table.TableReference(dataset_ref, table_id.split('.')[1])
    from google.cloud.exceptions import NotFound
    try:
        BIGQUERY_CLIENT.get_table(table_ref)
        return True
    except NotFound:
        return False


async def getTelegramInfo(client, user_input_channel, limitation):
    my_channel = await client.get_entity(user_input_channel)
    offset_id = 0
    limit = limitation
    all_messages = []
    total_messages = 0
    total_count_limit = limitation

    while True:
        history = await client(GetHistoryRequest(
            peer=my_channel,
            offset_id=offset_id,
            offset_date=None,
            add_offset=0,
            limit=limit,
            max_id=0,
            min_id=0,
            hash=0
        ))
        if not history.messages:
            break
        messages = history.messages
        for message in messages:
            all_messages.append(message.to_dict())
        offset_id = messages[len(messages) - 1].id
        total_messages = len(all_messages)
        if total_count_limit != 0 and total_messages >= total_count_limit:
            break
    return all_messages


async def wrapper(last_time_checked, GroupName, limitation):
    print('GroupName:', GroupName)
    await client.start()
    # alert_found_key_word.clear()
    if not await client.is_user_authorized():
        await client.send_code_request(phone)
        try:
            await client.sign_in(phone, input('Enter the code: '))
        except SessionPasswordNeededError:
            await client.sign_in(password=input('Password: '))

    me = await client.get_me()
    user_input_channel = f'https://t.me/{GroupName}'
    telegram_data = await getTelegramInfo(client, user_input_channel, limitation)

    telegram_ids = [item['id'] for item in telegram_data]
    ids_to_compare = []
    if is_tbl_exist(DEST_TABLE_ID):
        ids_to_compare = get_exist_ids('message_id')
    new_ids = [id_item for id_item in telegram_ids if id_item not in ids_to_compare]
    if new_ids:
        new_telegram_data = [msg for msg in telegram_data
                             if msg['id'] in new_ids
                             and msg['date'].strftime("%Y-%m-%d") > str(last_time_checked)]
        print('new_telegram_data len: ', len(new_telegram_data))
        data_list = []

        for item in new_telegram_data:
            formatted_date = item['date'].strftime("%Y-%m-%d")
            # case there is a message
            if 'message' in item.keys():
                # case there is a message and a file
                if isFileNameExist(item):
                    data_list.append({'group_name': GroupName,
                                      'message_id': item['id'],
                                      'message_content': item['message'],
                                      'file_name': item['media']['document']['attributes'][0]['file_name'],
                                      'message_date': formatted_date})
                # case there is a message but no file
                else:
                    data_list.append({'group_name': GroupName,
                                      'message_id': item['id'],
                                      'message_content': item['message'],
                                      'file_name': '',
                                      'message_date': formatted_date})
            # case there is no message but a file
            else:
                if isFileNameExist(item):
                    data_list.append({'group_name': GroupName,
                                      'message_id': item['id'],
                                      'message_content': '',
                                      'file_name': item['media']['document']['attributes'][0]['file_name'],
                                      'message_date': formatted_date})

        # create list of new checked IDS to avoid repeating check (history saver)
        ids_to_load.append([{'group_name': data_piece['group_name'],
                             'message_id': data_piece['message_id'],
                             'insert_date': datetime.today().strftime('%Y-%m-%d')}
                            for data_piece in data_list])

        # search for suspected words in the messages (generates a list of suspected messages)
        for msg in data_list:
            check_msg = re.sub(r"[^a-zA-Z0-9\s.]", "", msg['message_content'])
            CheckMsg(GroupName, msg, check_msg.lower())

    else:
        print("Didn't find anything interesting")


async def run():
    for i in ListOfChannels:
        await wrapper('2023-05-11', i, 150)
    for i in ListOfBigVolumeChannel:
        await wrapper('2023-05-11', i, 500)
    # loading new IDs to bigquery
    ids_df = pd.DataFrame([item for sublist in ids_to_load for item in sublist])
    upload_new_ids(ids_df)
    gcs_json_file_gen()


def main():
    asyncio.run(run())


if __name__ == '__main__':
    main()
