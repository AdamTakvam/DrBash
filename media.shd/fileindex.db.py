#!/bin/env python

import sqlite3

class FileIndexDB:
    DB_FILE = ".fileindex.db"
    conn = None
   
    def __init__(self):
        self.conn = sqlite3.connect("example.db")
        self.cursor().execute('''
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    q1 TEXT,
    q2 TEXT,
    q3 TEXT,
    q4 TEXT
)
''')

    def __del__(self):
        try:
            self.cursor().close()
            self.conn.close()
        except:
            pass
 
    def addtag(self, name, q1="", q2="", q3="", q4=""):
        try:
            self.cursor().execute(f"INSERT INTO tags (name, q1, q2, q3, q4) VALUES ({name}, {q1}, {q2}, {q3}, {q4})")
            self.conn.commit()
            return True
        except sqlite3.Error as e:
            self.conn.rollback()
            print("Error: ", e)
            return False

    def dumpdb(self):
        self.cursor().execute("SELECT * FROM tags")
        rows = self.cursor().fetchall()
        for row in rows:
            print(row)
 
    def cursor(self):
        return self.conn.cursor()
