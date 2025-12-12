import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CarretaDigitalApp());
}

// --- CONFIGURAÇÃO DE CORES ---
class AppColors {
  static const Color primaryBlue = Color(0xFF13008C);
  static const Color accentYellow = Color(0xFFF1E513);
  static const Color accentGreen = Color(0xFF00E676);
  static const Color background = Color(0xFFF5F5F5);
  static const Color pcdGreen = Color(0xFF82D6A7);
  static Color metaBoxColor = const Color(0xFFD9D9D9).withOpacity(0.28);
}

class CarretaDigitalApp extends StatelessWidget {
  const CarretaDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carreta Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        fontFamily: 'Roboto',
        // Remove a linha divisória padrão do ExpansionTile
        dividerColor: Colors.transparent,
      ),
      home: const HomePage(),
    );
  }
}

// --- MODELAGEM DE DADOS ---

class MapPoint {
  final String estado;
  final int qtd;
  final double lat;
  final double lng;

  MapPoint({required this.estado, required this.qtd, required this.lat, required this.lng});

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      estado: json['estado'] ?? '',
      qtd: json['qtd'] ?? 0,
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }
}

class DashboardData {
  final int totalAlunos;
  final int metaProjeto;
  final double porcentagemConcluida;
  final int totalEstados;
  final int totalEscolas;
  final int totalMunicipios; // NOVO CAMPO
  final List<MapPoint> pontosMapa;

  // DADOS ESPECÍFICOS PARA AS TELAS
  final Map<String, int> alunosPorEstado;
  final Map<String, Map<String, int>> municipiosPorEstado; // NOVO CAMPO ANINHADO
  final Map<String, int> alunosPorCurso;
  final Map<String, int> generos;
  final int totalPcd;

  DashboardData({
    required this.totalAlunos,
    required this.metaProjeto,
    required this.porcentagemConcluida,
    required this.totalEstados,
    required this.totalEscolas,
    required this.totalMunicipios,
    required this.pontosMapa,
    required this.alunosPorEstado,
    required this.municipiosPorEstado,
    required this.alunosPorCurso,
    required this.generos,
    required this.totalPcd,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpis'];
    final graficos = json['graficos'];

    var listaMapa = json['mapa'] as List? ?? [];
    List<MapPoint> pontos = listaMapa.map((i) => MapPoint.fromJson(i)).toList();

    Map<String, int> estadosMap = {};
    Map<String, Map<String, int>> municipiosMap = {};
    Map<String, int> cursosMap = {};
    Map<String, int> generosMap = {"Masculino": 0, "Feminino": 0};
    int pcd = 0;

    if (graficos != null) {
      // Estados
      if (graficos['alunos_por_estado'] != null) {
        (graficos['alunos_por_estado'] as Map<String, dynamic>).forEach((key, value) {
          estadosMap[key] = value as int;
        });
      }
      // Municípios por Estado (Novo processamento)
      if (graficos['municipios_por_estado'] != null) {
        (graficos['municipios_por_estado'] as Map<String, dynamic>).forEach((estado, cidades) {
          municipiosMap[estado] = Map<String, int>.from(cidades as Map);
        });
      }
      // Cursos
      if (graficos['alunos_por_curso'] != null) {
        (graficos['alunos_por_curso'] as Map<String, dynamic>).forEach((key, value) {
          cursosMap[key] = value as int;
        });
      }
      // Gênero
      if (graficos['generos'] != null) {
        (graficos['generos'] as Map<String, dynamic>).forEach((key, value) {
          generosMap[key] = value as int;
        });
      }
      // PCD
      pcd = graficos['total_pcd'] ?? 0;
    }

    return DashboardData(
      totalAlunos: kpis['total_alunos'] ?? 0,
      metaProjeto: kpis['meta_projeto'] ?? 0,
      porcentagemConcluida: (kpis['porcentagem_concluida'] ?? 0).toDouble(),
      totalEstados: kpis['total_estados'] ?? 0,
      totalEscolas: kpis['total_escolas'] ?? 0,
      totalMunicipios: kpis['total_municipios'] ?? 0,
      pontosMapa: pontos,
      alunosPorEstado: estadosMap,
      municipiosPorEstado: municipiosMap,
      alunosPorCurso: cursosMap,
      generos: generosMap,
      totalPcd: pcd,
    );
  }
}

// --- TELA PRINCIPAL (HOME) ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<DashboardData>? _dadosFuture;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    setState(() {
      _dadosFuture = fetchDashboardData();
    });
  }

  Future<DashboardData> fetchDashboardData() async {
    final url = Uri.parse('https://api-carreta.onrender.com/dados');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return DashboardData.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        toolbarHeight: 110,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Image.asset(
            'assets/images/logo.png',
            height: 180,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text("Carreta Digital", style: TextStyle(color: Colors.white));
            },
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dadosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 40, color: Colors.red),
                  const SizedBox(height: 10),
                  Text("Erro: ${snapshot.error}", textAlign: TextAlign.center),
                  ElevatedButton(onPressed: _carregarDados, child: const Text("Tentar Novamente"))
                ],
              )
            );
          } else if (snapshot.hasData) {
            final dados = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      "VISÃO GERAL DO PROJETO",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Acompanhamento em tempo real",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey)
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildMetaCard(dados),
                  const SizedBox(height: 20),

                  // Linha 1: Estados e Escolas
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard(Icons.map_outlined, "${dados.totalEstados}", "Estados")),
                      const SizedBox(width: 15),
                      Expanded(child: _buildInfoCard(Icons.school_outlined, "${dados.totalEscolas}", "Escolas")),
                    ],
                  ),
                  
                  const SizedBox(height: 15),

                  // Linha 2: Municípios (NOVO CARD, OCUPANDO LARGURA TOTAL)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        // Você pode alterar o ícone se quiser, usei 'location_city'
                        const SizedBox(height: 5),
                        Text("${dados.totalMunicipios}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const Text("Municípios e RAs", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // MAPA (TRAVADO)
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: const LatLng(-15.7998, -47.8645),
                              initialZoom: 3.8,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                              cameraConstraint: CameraConstraint.contain(
                                bounds: LatLngBounds(
                                  const LatLng(6.0, -74.0),
                                  const LatLng(-34.0, -34.0),
                                ),
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.carretadigital.app',
                              ),
                              MarkerLayer(
                                markers: dados.pontosMapa.map((ponto) {
                                  return Marker(
                                    point: LatLng(ponto.lat, ponto.lng),
                                    width: 60,
                                    height: 60,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.accentYellow,
                                          width: 3
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 5,
                                            offset: const Offset(0, 3)
                                          )
                                        ]
                                      ),
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              "${ponto.qtd}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                              ),
                              child: Text(
                                "${dados.pontosMapa.length} Estados Ativos",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 12),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                  
                  // MENU DE NAVEGAÇÃO
                  _buildNavButton(
                    context: context,
                    label: "Estados",
                    icon: Icons.map,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EstadosPage(
                        dadosEstados: dados.alunosPorEstado,
                        municipiosPorEstado: dados.municipiosPorEstado, // Passando o novo dado
                      )));
                    }
                  ),
                  _buildNavButton(
                    context: context,
                    label: "Alunos",
                    icon: Icons.person_3,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AlunosPage(generos: dados.generos, totalPcd: dados.totalPcd)));
                    }
                  ),
                  _buildNavButton(
                    context: context,
                    label: "Cursos",
                    icon: Icons.menu_book,
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => CursosPage(dadosCursos: dados.alunosPorCurso)));
                    }
                  ),
                  _buildNavButton(
                    context: context,
                    label: "Buscar Certificados",
                    icon: Icons.search, 
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CertificadosPage()));
                    }
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetaCard(DashboardData dados) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("META DO PROJETO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Text("${dados.totalAlunos}/${dados.metaProjeto}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: dados.porcentagemConcluida,
              backgroundColor: Colors.black26,
              color: AppColors.accentYellow,
              minHeight: 15,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.metaBoxColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text("${(dados.porcentagemConcluida * 100).toStringAsFixed(0)}% concluído", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.black87),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNavButton({required BuildContext context, required String label, required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))]
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PÁGINA: DETALHES DOS ESTADOS (COM DROPDOWN DE MUNICÍPIOS) ---
class EstadosPage extends StatelessWidget {
  final Map<String, int> dadosEstados;
  final Map<String, Map<String, int>> municipiosPorEstado;

  const EstadosPage({super.key, required this.dadosEstados, required this.municipiosPorEstado});

  @override
  Widget build(BuildContext context) {
    final listaOrdenada = dadosEstados.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dados dos Estados", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text("PRESENÇA NOS ESTADOS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Toque para ver os municípios", style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: listaOrdenada.length,
              itemBuilder: (context, index) {
                final estado = listaOrdenada[index];
                
                // LÓGICA DE META
                String nomeEstado = estado.key.toUpperCase();
                int metaLocal = 3000;
                if (nomeEstado.contains("SANTA CATARINA") || nomeEstado.contains("FLORIAN")) {
                  metaLocal = 1000;
                }
                double porcentagem = (estado.value / metaLocal).clamp(0.0, 1.0);

                // RECUPERA MUNICÍPIOS DESTE ESTADO
                Map<String, int> municipios = municipiosPorEstado[estado.key] ?? {};
                // Ordena municípios do maior para o menor
                var municipiosOrdenados = municipios.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      // HEADER (O que já existia)
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(estado.key, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text("${estado.value}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: porcentagem,
                              minHeight: 12,
                              backgroundColor: Colors.black87,
                              color: AppColors.accentYellow
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text("${(porcentagem * 100).toStringAsFixed(0)}% da meta local ($metaLocal)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      // BODY (Lista de Municípios)
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50], // Fundo levemente cinza para diferenciar
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                          ),
                          child: Column(
                            children: municipiosOrdenados.isEmpty 
                              ? [const Text("Sem dados detalhados.", style: TextStyle(color: Colors.grey))]
                              : municipiosOrdenados.map((cidade) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(cidade.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                                        Text("${cidade.value}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- PÁGINA: DETALHES DOS ALUNOS ---
class AlunosPage extends StatelessWidget {
  final Map<String, int> generos;
  final int totalPcd;

  const AlunosPage({super.key, required this.generos, required this.totalPcd});

  @override
  Widget build(BuildContext context) {
    String formatNumber(int num) {
      return num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dados dos Alunos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("ANÁLISE DOS ALUNOS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text("Acompanhamento em tempo real", style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(child: _buildGenderCard(title: "Homens", value: formatNumber(generos['Masculino'] ?? 0))),
                const SizedBox(width: 15),
                Expanded(child: _buildGenderCard(title: "Mulheres", value: formatNumber(generos['Feminino'] ?? 0))),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: AppColors.pcdGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatNumber(totalPcd), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.black87)),
                      const Text("Alunos PCD", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const Icon(Icons.accessible, size: 70, color: Colors.black87),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}

// --- PÁGINA: DETALHES DOS CURSOS ---
class CursosPage extends StatelessWidget {
  final Map<String, int> dadosCursos;

  const CursosPage({super.key, required this.dadosCursos});

  @override
  Widget build(BuildContext context) {
    final listaOrdenada = dadosCursos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int maiorQuantidade = listaOrdenada.isNotEmpty ? listaOrdenada.first.value : 1;
    if (maiorQuantidade == 0) maiorQuantidade = 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dados dos Cursos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text("ALUNOS POR CURSO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text("Acompanhamento em tempo real", style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: listaOrdenada.length,
              itemBuilder: (context, index) {
                final curso = listaOrdenada[index];
                double porcentagem = (curso.value / maiorQuantidade);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              curso.key,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text("${curso.value}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: porcentagem,
                          minHeight: 12,
                          backgroundColor: Colors.black,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- MODELO ---
class Certificado {
  final String nome;
  final String curso;
  final String link;
  final String estado;

  Certificado({
    required this.nome,
    required this.curso,
    required this.link,
    required this.estado,
  });

  factory Certificado.fromJson(Map<String, dynamic> json) {
    return Certificado(
      nome: json['nome'] ?? '',
      curso: json['curso'] ?? '',
      link: json['link'] ?? '',
      estado: json['estado'] ?? 'Estado não informado',
    );
  }
}

// --- TELA DE BUSCA ---
class CertificadosPage extends StatefulWidget {
  const CertificadosPage({super.key});

  @override
  State<CertificadosPage> createState() => _CertificadosPageState();
}

class _CertificadosPageState extends State<CertificadosPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Certificado> _certificados = [];
  bool _isLoading = false;
  String _mensagem = "";
  int _totalEncontrados = 0;
  bool _buscaRealizada = false;

  // COR AMARELA PADRÃO DO APP
  final Color accentYellow = const Color(0xFFF1E513);
  final Color primaryBlue = const Color(0xFF13008C);

  // Função para buscar na API
  Future<void> _buscarCertificados() async {
    String nomeBusca = _searchController.text.trim();
    if (nomeBusca.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _mensagem = "Buscando...";
      _certificados = [];
      _totalEncontrados = 0;
      _buscaRealizada = false;
    });

    final url = Uri.parse('https://api-carreta.onrender.com/certificados?nome=$nomeBusca');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final int totalAPI = data['total'] ?? 0;
        final List<dynamic> listaResultados = data['resultados'] ?? [];

        setState(() {
          _certificados = listaResultados.map((item) => Certificado.fromJson(item)).toList();
          _totalEncontrados = totalAPI;
          _isLoading = false;
          _buscaRealizada = true;
          
          if (_certificados.isEmpty) {
            _mensagem = "Nenhum certificado encontrado para '$nomeBusca'.";
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _mensagem = "Erro ao buscar: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensagem = "Erro de conexão. Verifique sua internet.";
      });
    }
  }

  Future<void> _abrirLink(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Certificados", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        toolbarHeight: 80,
        actions: [
           IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _certificados = [];
                _totalEncontrados = 0;
                _mensagem = "";
                _buscaRealizada = false;
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF5F5F5),
            padding: const EdgeInsets.only(top: 20, bottom: 5),
            child: const Column(
              children: [
                Text(
                  "CERTIFICADOS",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  "Acompanhamento em tempo real",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black87, width: 1.0),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Digite o nome do aluno",
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: const Icon(Icons.search, color: Colors.black87),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.arrow_forward, color: primaryBlue),
                        onPressed: _buscarCertificados,
                      ),
                    ),
                    onSubmitted: (_) => _buscarCertificados(),
                  ),
                ),
                
                const SizedBox(height: 10),

                if (!_isLoading && _buscaRealizada) 
                  Text(
                    "Total de alunos encontrados: $_totalEncontrados",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                
                const SizedBox(height: 10),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  )
                else if (_certificados.isEmpty && _mensagem.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(_mensagem, style: const TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _certificados.length,
              itemBuilder: (context, index) {
                final cert = _certificados[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NOME (Mantém Branco)
                            Text(
                              cert.nome,
                              style: const TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.white
                              ),
                            ),
                            const SizedBox(height: 4),
                            // ESTADO (Agora Amarelo)
                            Text(
                              cert.estado,
                              style: TextStyle(fontSize: 16, color: accentYellow, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            // CURSO (Agora Amarelo)
                            Text(
                              cert.curso,
                              style: TextStyle(fontSize: 16, color: accentYellow),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _abrirLink(cert.link),
                        icon: const Icon(Icons.file_download_outlined, size: 30, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}