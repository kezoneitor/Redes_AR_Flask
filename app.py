from flask import (Flask, render_template, request)
from werkzeug.utils import redirect
from flask import url_for, flash
from snmp_program import *
from database import *
import psycopg2

default_community = 'public'

app = Flask(__name__, template_folder="templates")
app.secret_key = "super secret key"

# DB requests
def getAdministrators():
    connection = None;
    cursor = None;
    try:
        connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres', password='12345', host='localhost')
        cursor = connection.cursor()
        cursor.execute("SELECT get_users()")
        record = cursor.fetchall()
        return record[0][0]
    finally:
        if(connection):
            cursor.close()
            connection.close()
            print("End connection")

def getModels():
    connection = None;
    cursor = None;
    try:
        connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres',
                                      password='12345', host='localhost')
        cursor = connection.cursor()
        cursor.execute("SELECT get_models()")
        record = cursor.fetchall()
        return record[0][0]
    finally:
        if (connection):
            cursor.close()
            connection.close()
            print("End connection")

def addModel(model):
    connection = None;
    cursor = None;
    try:
        connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres',
                                      password='12345', host='localhost')
        connection.autocommit = True
        cursor = connection.cursor()
        cursor.execute("SELECT insert_new_model('" + model + "')")
        record = cursor.fetchall()
        return record[0][0]
    finally:
        if (connection):
            cursor.close()
            connection.close()
            print("End connection")

def addDevice(administrator, name, ip, model):
    connection = None;
    cursor = None;
    try:
        connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres',
                                      password='12345', host='localhost')
        connection.autocommit = True
        cursor = connection.cursor()
        cursor.execute(
            "SELECT insert_new_device(" + administrator + ", '" + name + "', '" + ip + "'::inet::cidr, " + model + ")")
        record = cursor.fetchall()
        return record[0][0]
    finally:
        if (connection):
            cursor.close()
            connection.close()
            print("End connection")

def addOids(id_model,oidsList):
    connection = None;
    cursor = None;
    try:
        connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres',
                                      password='12345', host='localhost')
        connection.autocommit = True
        cursor = connection.cursor()
        for i in oidsList:
            cursor.execute(
                "SELECT insert_new_oids(" + id_model + ", '" + i["description"] + "', '" + i["mib"] + "')")
        return True

    finally:
        if (connection):
            cursor.close()
            connection.close()
            print("End connection")

# Create a URL route in our application for "/"
@app.route('/')
def home():
    users = [(di['id_administrator'], di['user_name']) for di in getAdministrators()]

    possible_models = getModels()
    possible_models.append({'id_model':len(possible_models)+1,'device_model':'Other'})
    models = [(di['id_model'], di['device_model']) for di in possible_models]

    return render_template('main.html', users=users, models=models)


@app.route('/newDevice', methods=['POST'])
def saveDevice():
    if (request.form["model"] != "noNeeded"):
        id_model = addModel(request.form["model"])
        addDevice(request.form["users"], request.form["name"], request.form["IP"], str(id_model))
        return render_template('mibs.html', deviceModelName=request.form["model"], deviceModelID=id_model)
    else:
        addDevice(request.form["users"], request.form["name"], request.form["IP"], request.form["models"])
        flash('Device added successfully, oids already exists for selected model')
        return redirect(url_for('home'))

@app.route('/newOids', methods=['POST'])
def saveOids():

    oidsList =[{"description":"interfaces amount","mib":request.form["oidNumber"]},{"description":"ip interfaces","mib":request.form["oidIp"]},
               {"description": "interfaces description", "mib": request.form["oidDescription"]}, {"description":"interfaces input packages","mib":request.form["oidInputP"]},
               {"description": "interfaces output packages", "mib": request.form["oidOutputP"]}]

    addOids(request.form["deviceID"], oidsList)
    flash('Device and oids added successfully')
    return redirect(url_for('home'))


@app.route('/getDeviceInformation', methods=['POST', 'GET'])
def getDeviceInformation():
    #response = json.loads(request.form)
    #target = response['SWID']
    target = request.form['SWID']
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
    user = connection("SELECT obtain_device_information(" + target + ")")[0]
    return user["email"]

# Run application
if __name__ == '__main__':
    app.run(port='5000')