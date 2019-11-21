from flask import (Flask, render_template, request)
import json
from snmp_program import *
from database import *

default_community = 'public'

# Create the application instance
app = Flask(__name__, template_folder="templates")

# DB requests
def getAdministrators():
    connection = None;
    cursor = None;
    data = None
    try:
        connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres',
                                        password='12345', host='localhost')
        cursor = connection.cursor()
        cursor.execute("SELECT get_users()")
        record = cursor.fetchall()
        data = record[0][0]
    finally:
        if (connection):
                cursor.close()
                connection.close()
                print("End connection")
    return data

def getModels():
    connection = None;
    cursor = None;
    data = None
    try:
        connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres',
                                      password='12345', host='localhost')
        cursor = connection.cursor()
        cursor.execute("SELECT get_models()")
        record = cursor.fetchall()
        data = record[0][0]
    finally:
        if (connection):
                cursor.close()
                connection.close()
                print("End connection")
    return data


# Create a URL route in our application for "/"
@app.route('/')
def home():
    users = [(di['id_administrator'], di['user_name']) for di in getAdministrators()]

    possible_models = getModels()
    possible_models.append({'id_model':len(possible_models)+1,'device_model':'Other'})
    models = [(di['id_model'], di['device_model']) for di in possible_models]

    return render_template('main.html', users=users, models=models)


@app.route('/newDevice', methods = ['POST'])
def saveDevice():
    deviceName = request.form["name"]
    #return render_template('mibs.html', deviceName=deviceName)


@app.route('/getDeviceInformation', methods=['POST', 'GET'])
def getDeviceInformation():
    #response = json.loads(request.form)
    #target = response['SWID']
    target = request.form['SWID']
    print(target)
    user = connection("SELECT obtain_device_information(" + target + ")")[0]
    oids = connection("SELECT obtain_mibs(" + target + ")")
    ip = user["ip"].split('/')[0]
    
    lenInterfaces = get(ip, [oids[0]["mib"]],
                        hlapi.CommunityData(default_community))
    results = []
    for interface in range(1, lenInterfaces[oids[0]["mib"]]+1):
        dataInterface = []
        for oid in range(1, len(oids)):
                dataInterface.append(oids[oid]["mib"]+'.'+str(interface))
        results.append(list(get(ip, dataInterface, hlapi.CommunityData(default_community)).values()))

    last_data = results[len(results) - 1]
    data_str = ''
    for result in results:
        data_str += str((result[1]+result[2])*100//(last_data[1] + last_data[2]))+","+','.join(str(v) for v in result)+";"
    return data_str[:len(data_str)-1]

@app.route('/getEmail', methods = ['POST', 'GET'])
def getEmail():
    #response = json.loads(request.form)
    #target = response['SWID']
    target = request.form['SWID']
    print(target)
    user = connection("SELECT obtain_device_information(" + target + ")")[0]
    return user["email"]

# Run application
if __name__ == '__main__':
    app.run(host='0.0.0.0', port='5000')
