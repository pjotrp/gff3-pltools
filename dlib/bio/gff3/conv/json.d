module bio.gff3.conv.json;

import std.array;
import bio.gff3.record, bio.gff3.record_range, bio.gff3.selection,
       bio.gff3.feature, bio.gff3.feature_range;

/**
 * Functions which convert a Record object to a string in JSON format. The
 * result is in the following form, but without spaces:
 * {
 *   "seqname" : "value of seqname",
 *   "source"  : "value of source",
 *   "feature" : "value of feature",
 *   "start"   : "value of start",
 *   "end"     : "value of end",
 *   "score"   : "value of score",
 *   "strand"  : "value of strand",
 *   "phase"   : "value of phase",
 *   "attributes"   : {
 *        "attr name 1" : "attr value 1",
 *        "attr name 2" : "attr value 2",
 *                     . . .
 *        "attr name n" : "attr value n",
 *   }
 * }
 */

void to_json(FeatureRange features, File output) {
  output.write('[');

  bool first_feature = true;
  foreach(feature; features) {
    if (!first_feature)
      output.write(',');
    else
      first_feature = false;

    output.write(feature.to_json());
  }

  output.write(']');
}

string to_json(Feature feature) {
  Appender!string app;
  to_json(feature, app);
  return app.data;
}

void to_json(Feature feature, ref Appender!string app) {
  app.put("{\"records\":[");
  foreach(rec; feature.records) {
    rec.to_json(app);
  }
  app.put("]}");
}

string to_json(GenericRecordRange records) {
  Appender!string app;
  to_json(records, app);
  return app.data;
}

void to_json(GenericRecordRange records, ref Appender!string app) {
  app.put('[');

  bool first_attr = true;
  foreach(rec; records) {
    if (!first_attr)
      app.put(',');
    else
      first_attr = false;
    rec.to_json(app);
  }

  app.put(']');
}

bool to_json(GenericRecordRange records, File output, long at_most = -1, string selection = null) {
  // First prepare the selector delegate
  ColumnsSelector selector = null;
  string[] columns = null;
  if (selection !is null) {
    selector = to_selector(selection);
    columns = split(selection, ",");
  }

  // start output
  output.write('[');

  long counter = 0;
  bool first_attr = true;
  foreach(rec; records) {
    if (!first_attr)
      output.write(',');
    else
      first_attr = false;

    if (selector is null)
      output.write(rec.to_json());
    else
      output.write(rec.to_json(selector, columns));
    counter += 1;

    // Check if the "at_most" limit has been reached
    if (counter == at_most) {
      output.write(",{\"limit_reached\":\"yes\"}");
      return true;
    }
  }

  output.write(']');

  return false;
}


void to_json(Record record, File output) {
  output.write(record.to_json());
}

string to_json(Record record, ColumnsSelector selector = null, string[] column_names = null) {
  Appender!string app;

  if (selector is null)
    record.to_json(app);
  else
    record.to_json(app, selector, column_names);

  return app.data;
}

void to_json(Record record, ref Appender!string app) {
  app.put('{');

  if (record.is_regular) {
    app.put("\"seqname\":\"");
    app.put(record.seqname);
    app.put("\",\"source\":\"");
    app.put(record.source);
    app.put("\",\"feature\":\"");
    app.put(record.feature);
    app.put("\",\"start\":\"");
    app.put(record.start);
    app.put("\",\"end\":\"");
    app.put(record.end);
    app.put("\",\"score\":\"");
    app.put(record.score);
    app.put("\",\"strand\":\"");
    app.put(record.strand);
    app.put("\",\"phase\":\"");
    app.put(record.phase);
    app.put("\",\"attributes\":{");

    bool first_attr = true;
    foreach(attr_name, attr_value; record.attributes) {
      if (!first_attr)
        app.put(',');
      else
        first_attr = false;
      app.put("\"");
      app.put(attr_name);
      app.put("\":\"");
      app.put(attr_value.toString());
      app.put('\"');
    }
    app.put("}");
  } else if (record.is_comment) {
    app.put("\"comment\":\"");
    app.put(record.toString());
    app.put('\"');
  } else {
    app.put("\"pragma\":\"");
    app.put(record.toString());
    app.put('\"');
  }

  app.put('}');
}

void to_json(Record record, Appender!string app, ColumnsSelector selector, string[] column_names) {
  auto columns = selector(record);

  app.put('{');

  if (record.is_regular) {
    bool first_attr = true;
    foreach(i, column_name; column_names) {
      if (!first_attr)
        app.put(',');
      else
        first_attr = false;
      app.put('\"');
      app.put(column_name);
      app.put("\":\"");
      app.put(columns[i]);
      app.put('\"');
    }
  } else if (record.is_comment) {
    app.put("\"comment\":\"");
    app.put(record.toString());
    app.put('\"');
  } else {
    app.put("\"pragma\":\"");
    app.put(record.toString());
    app.put('\"');
  }

  app.put('}');
}



import std.stdio;

unittest {
  writeln("Testing to_json(Record)...");

  auto record = new Record(".\t.\t.\t.\t.\t.\t.\t.\t.");
  assert(record.to_json() == "{\"seqname\":\"\",\"source\":\"\",\"feature\":\"\",\"start\":\"\",\"end\":\"\",\"score\":\"\",\"strand\":\"\",\"phase\":\"\",\"attributes\":[]}");

  record = new Record(".\t.\t.\t.\t.\t.\t.\t.\tID=testing");
  assert(record.to_json() == "{\"seqname\":\"\",\"source\":\"\",\"feature\":\"\",\"start\":\"\",\"end\":\"\",\"score\":\"\",\"strand\":\"\",\"phase\":\"\",\"attributes\":[\"ID\":\"testing\"]}");

  record = new Record("1\t2\t3\t4\t5\t6\t7\t8\tID=testing");
  assert(record.to_json() == "{\"seqname\":\"1\",\"source\":\"2\",\"feature\":\"3\",\"start\":\"4\",\"end\":\"5\",\"score\":\"6\",\"strand\":\"7\",\"phase\":\"8\",\"attributes\":[\"ID\":\"testing\"]}");
}

