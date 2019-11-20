import psycopg2

def connection(query):
      connection = None
      cursor = None
      data = None
      try:
            connection = psycopg2.connect(port='5432', database='Network_Devices', user='postgres',
                                          password='12345', host='localhost')
            cursor = connection.cursor()
            cursor.execute(query)
            record = cursor.fetchall()
            data = record[0][0]
      finally:
            if (connection):
                  cursor.close()
                  connection.close()
                  print("End connection")
      return data
