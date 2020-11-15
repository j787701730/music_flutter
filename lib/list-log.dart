import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListLog extends StatefulWidget {
  @override
  _ListLogState createState() => _ListLogState();
}

class _ListLogState extends State<ListLog> {
  List cityData = [];
  bool change = false;

  _cityChange(value) async {
    change = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String logs = prefs.getString('logs');
    List data = [];
    if (logs == null) {
      data.add(value);
    } else {
      data = jsonDecode(logs);
      for (var o in data) {
        if (o['id'] == value['id']) {
          data.remove(o);
          break;
        }
      }
      data.insert(0, value);
    }
    await prefs.setString('logs', jsonEncode(data));
    Navigator.of(context).pop(change);
  }

  _getCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String logs = prefs.getString('logs');
    if (logs != null) {
      setState(() {
        cityData = jsonDecode(logs);
      });
    }
  }

  _delCity(index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cityData.removeAt(index);
    prefs.setString('logs', jsonEncode(cityData));
    setState(() {
      change = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _getCity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop(change);
          },
        ),
        elevation: 1,
        title: Text(
          '历史记录',
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 8),
        separatorBuilder: (BuildContext context, int index) {
          return Divider();
        },
        itemBuilder: (context, index) {
          Map item = cityData[index];
          return ListTile(
            key: Key('${item['id']}'),
            title: Row(
              children: [
                Text(item['name']),
                Text(
                  '   (${item['country']} ${item['adm1']} ${item['adm2']})',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            onTap: () {
              _cityChange(item);
            },
            trailing: IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.red,
              ),
              onPressed: () => {_delCity(index)},
            ),
          );
        },
        itemCount: cityData.length,
      ),
    );
  }
}
