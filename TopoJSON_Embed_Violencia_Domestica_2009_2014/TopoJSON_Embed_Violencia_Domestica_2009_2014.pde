void setup() {
  String dataFilename = "violencia-domestica/data/dgai_violencia_domestica_2008_2014.csv";
  String geoFilename = "pt_shp/PRT_adm1.topo.json";

  Table table = loadTable(dataFilename, "header, csv");
  table.setMissingString("ND");
  String[] distritos = table.getUnique("Distrito");
  String[] anos = table.getUnique("Ano");
  float[] factorDistritos = new float[distritos.length];
  int[] totaisDistritos = new int[distritos.length];
  JSONArray output = new JSONArray();

  int dataMin = MAX_INT;
  int dataMax = MIN_INT;
  int total = 0;

  for (int i = 0; i < table.getRowCount(); i++) {
    int value = table.getInt(i, "Valor");
    total += value;
    if (value > dataMax) {
      dataMax = value;
    }
    if (value < dataMin) {
      dataMin = value;
    }
  }

  println(total, dataMin, dataMax);

  for (int i = 0; i < distritos.length; i++) {
    JSONObject distrito = new JSONObject();
    JSONArray valores  = new JSONArray();

    for (int j=0; j<table.getRowCount(); j++) {
      if (table.getString(j, "Distrito").equals(distritos[i])) {
        try {
          //println(table.getString(j, "Distrito"), table.getString(j, "Entidade"));
          factorDistritos[i] = map(table.getFloat(j, "Valor"), dataMin, dataMax, 0, 1);
          totaisDistritos[i] += table.getInt(j, "Valor");
        } 
        catch (Exception e) {
        }
      }
    }
   // println(distritos[i], factorDistritos[i]);

    for (int j=0; j<anos.length; j++) {
      JSONObject ano = new JSONObject();      
      JSONArray entidades = new JSONArray();

      for (TableRow row : table.findRows(anos[j], "Ano")) {
        if (row.getString("Distrito").equals(distritos[i])) {
          JSONObject valor = new JSONObject();
          valor.setString(row.getString("Entidade"), row.getString("Valor"));
          entidades.append(valor);
        }
      }
      ano.setString("Ano", anos[j]);
      ano.setJSONArray("Entidade", entidades);
      valores.append(ano);
    }
    distrito.setInt("Somatorio_amostra", totaisDistritos[i]);
    distrito.setFloat("Factor_amostra", factorDistritos[i]);
    distrito.setString("Distrito", distritos[i]);
    distrito.setJSONArray("Valores", valores);
    output.setJSONObject(i, distrito);
  }

  //println(output.toString());
  JSONObject topoJSON = loadJSONObject(geoFilename);
  JSONArray geometries = topoJSON.getJSONObject("objects").getJSONObject("PRT_adm1").getJSONArray("geometries");

  for (int i=0; i<geometries.size(); i++) {
    for (int j=0; j<output.size(); j++) {
      String datasetDistrictName = output.getJSONObject(j).getString("Distrito")+" ";
      String shapefileDistrictName = geometries.getJSONObject(i).getJSONObject("properties").getString("NAME_1")+" ";
      boolean match = datasetDistrictName.contains(shapefileDistrictName);
      if (match) {
        geometries.getJSONObject(i).getJSONObject("properties").setJSONObject("dgai_violencia_domestica_2008_2014", output.getJSONObject(j));
      }
    }
  }
  println(topoJSON);
  saveJSONObject(topoJSON, "dgai_violencia_domestica_2008_2014.topo.json");
  //println(distritos);
  //println(totaisDistritos);
}