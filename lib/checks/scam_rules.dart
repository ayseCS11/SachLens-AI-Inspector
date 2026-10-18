import '../core/signal.dart';

// Offline checks for the wording that scam letters, offers and messages use.
/// They read only the text and send nothing anywhere.

/// Well known institutions and the web domains they really use.
/// Extend this list with the universities your users care about.
///
/// The first block is the original hand picked list. The second block comes
/// from the UI GreenMetric World University Rankings 2025 (world rank 1 to 418,
/// the part of the table that was available). Keys are lowercase names, values
/// are the official web domains taken from the ranking site.
const Map<String, List<String>> _knownIssuers = {
  // Original entries
  'harvard': ['harvard.edu'],
  'stanford university': ['stanford.edu'],
  'massachusetts institute of technology': ['mit.edu'],
  'yale university': ['yale.edu'],
  'princeton university': ['princeton.edu'],
  'columbia university': ['columbia.edu'],
  'university of oxford': ['ox.ac.uk'],
  'university of cambridge': ['cam.ac.uk'],
  'imperial college london': ['imperial.ac.uk'],
  'university of toronto': ['utoronto.ca'],
  'university of melbourne': ['unimelb.edu.au'],
  'national university of singapore': ['nus.edu.sg'],
  'tsinghua university': ['tsinghua.edu.cn'],
  'eth zurich': ['ethz.ch'],
  // Additional world universities
  // United States
  'university of pennsylvania': ['upenn.edu'],
  'cornell university': ['cornell.edu'],
  'brown university': ['brown.edu'],
  'dartmouth college': ['dartmouth.edu'],
  'duke university': ['duke.edu'],
  'johns hopkins university': ['jhu.edu'],
  'northwestern university': ['northwestern.edu'],
  'university of chicago': ['uchicago.edu'],
  'california institute of technology': ['caltech.edu'],
  'university of california, berkeley': ['berkeley.edu'],
  'uc berkeley': ['berkeley.edu'],
  'university of california, los angeles': ['ucla.edu'],
  'ucla': ['ucla.edu'],
  'university of california, san diego': ['ucsd.edu'],
  'uc san diego': ['ucsd.edu'],
  'university of california, santa barbara': ['ucsb.edu'],
  'university of california, irvine': ['uci.edu'],
  'university of california, santa cruz': ['ucsc.edu'],
  'university of california, riverside': ['ucr.edu'],
  'university of california, merced': ['ucmerced.edu'],
  'university of california, san francisco': ['ucsf.edu'],
  'university of michigan': ['umich.edu'],
  'carnegie mellon university': ['cmu.edu'],
  'new york university': ['nyu.edu'],
  'university of texas at austin': ['utexas.edu'],
  'georgia institute of technology': ['gatech.edu'],
  'university of illinois urbana-champaign': ['illinois.edu'],
  'university of wisconsin-madison': ['wisc.edu'],
  'purdue university': ['purdue.edu'],
  'boston university': ['bu.edu'],
  'boston college': ['bc.edu'],
  'university of southern california': ['usc.edu'],
  'emory university': ['emory.edu'],
  'rice university': ['rice.edu'],
  'vanderbilt university': ['vanderbilt.edu'],
  'university of north carolina at chapel hill': ['unc.edu'],
  'ohio state university': ['osu.edu'],
  'pennsylvania state university': ['psu.edu'],
  'university of florida': ['ufl.edu'],
  'university of maryland': ['umd.edu'],
  'university of minnesota': ['umn.edu'],
  'university of virginia': ['virginia.edu'],
  'texas a&m university': ['tamu.edu'],
  'university of washington': ['uw.edu'],
  'washington university in st. louis': ['wustl.edu'],
  'university of colorado boulder': ['colorado.edu'],
  'arizona state university': ['asu.edu'],
  'university of arizona': ['arizona.edu'],
  'university of utah': ['utah.edu'],
  'indiana university': ['indiana.edu'],
  'michigan state university': ['msu.edu'],
  'university of pittsburgh': ['pitt.edu'],
  'rutgers university': ['rutgers.edu'],
  'university of massachusetts amherst': ['umass.edu'],
  'university of miami': ['miami.edu'],
  'virginia tech': ['vt.edu'],
  'north carolina state university': ['ncsu.edu'],
  'university of georgia': ['uga.edu'],
  'university of iowa': ['uiowa.edu'],
  'iowa state university': ['iastate.edu'],
  'university of oregon': ['uoregon.edu'],
  'oregon state university': ['oregonstate.edu'],
  'fordham university': ['fordham.edu'],
  'syracuse university': ['syr.edu'],
  'drexel university': ['drexel.edu'],
  'rensselaer polytechnic institute': ['rpi.edu'],
  'worcester polytechnic institute': ['wpi.edu'],
  'stony brook university': ['stonybrook.edu'],
  'university at buffalo': ['buffalo.edu'],
  'clemson university': ['clemson.edu'],
  'baylor university': ['baylor.edu'],
  'university of houston': ['uh.edu'],
  'university of cincinnati': ['uc.edu'],
  'university of kansas': ['ku.edu'],
  'university of alabama': ['ua.edu'],
  'university of rochester': ['rochester.edu'],
  'case western reserve university': ['case.edu'],
  'university of notre dame': ['nd.edu'],
  'georgetown university': ['georgetown.edu'],
  'tufts university': ['tufts.edu'],
  'brandeis university': ['brandeis.edu'],

  // Canada
  'university of british columbia': ['ubc.ca'],
  'mcgill university': ['mcgill.ca'],
  'university of alberta': ['ualberta.ca'],
  'mcmaster university': ['mcmaster.ca'],
  'university of waterloo': ['uwaterloo.ca'],
  'université de montréal': ['umontreal.ca'],
  'university of montreal': ['umontreal.ca'],
  'simon fraser university': ['sfu.ca'],
  'university of ottawa': ['uottawa.ca'],
  'university of calgary': ['ucalgary.ca'],
  'western university': ['uwo.ca'],
  'dalhousie university': ['dal.ca'],
  'university of victoria': ['uvic.ca'],
  'concordia university': ['concordia.ca'],
  'carleton university': ['carleton.ca'],
  'university of manitoba': ['umanitoba.ca'],
  'university of saskatchewan': ['usask.ca'],
  'université laval': ['ulaval.ca'],
  'toronto metropolitan university': ['torontomu.ca', 'ryerson.ca'],

  // United Kingdom
  'university college london': ['ucl.ac.uk'],
  "king's college london": ['kcl.ac.uk'],
  'london school of economics': ['lse.ac.uk'],
  'university of edinburgh': ['ed.ac.uk'],
  'university of manchester': ['manchester.ac.uk'],
  'university of bristol': ['bristol.ac.uk'],
  'university of warwick': ['warwick.ac.uk'],
  'university of glasgow': ['gla.ac.uk'],
  'durham university': ['durham.ac.uk'],
  'university of st andrews': ['st-andrews.ac.uk'],
  'university of birmingham': ['bham.ac.uk', 'birmingham.ac.uk'],
  'university of leeds': ['leeds.ac.uk'],
  'university of sheffield': ['sheffield.ac.uk', 'shef.ac.uk'],
  'university of southampton': ['soton.ac.uk'],
  'university of nottingham': ['nottingham.ac.uk'],
  'university of liverpool': ['liverpool.ac.uk'],
  'queen mary university of london': ['qmul.ac.uk'],
  'university of bath': ['bath.ac.uk'],
  'cardiff university': ['cardiff.ac.uk'],
  'university of exeter': ['exeter.ac.uk'],
  'university of york': ['york.ac.uk'],
  'lancaster university': ['lancaster.ac.uk'],
  'newcastle university': ['ncl.ac.uk'],
  'university of aberdeen': ['abdn.ac.uk'],
  'university of sussex': ['sussex.ac.uk'],
  'loughborough university': ['lboro.ac.uk'],
  'university of surrey': ['surrey.ac.uk'],
  'university of reading': ['reading.ac.uk'],
  'university of leicester': ['le.ac.uk'],
  'university of east anglia': ['uea.ac.uk'],
  'university of strathclyde': ['strath.ac.uk'],
  "queen's university belfast": ['qub.ac.uk'],
  'university of dundee': ['dundee.ac.uk'],
  'swansea university': ['swansea.ac.uk'],
  'university of kent': ['kent.ac.uk'],
  'brunel university': ['brunel.ac.uk'],
  'university of essex': ['essex.ac.uk'],
  'university of westminster': ['westminster.ac.uk'],
  'university of chester': ['chester.ac.uk'],
  'coventry university': ['coventry.ac.uk'],

  // Ireland
  'trinity college dublin': ['tcd.ie'],
  'university college dublin': ['ucd.ie'],
  'university of galway': ['universityofgalway.ie', 'nuigalway.ie'],

  // Western and Northern Europe
  'university of copenhagen': ['ku.dk'],
  'technical university of denmark': ['dtu.dk'],
  'aarhus university': ['au.dk'],
  'lund university': ['lu.se'],
  'uppsala university': ['uu.se'],
  'kth royal institute of technology': ['kth.se'],
  'stockholm university': ['su.se'],
  'karolinska institutet': ['ki.se'],
  'chalmers university of technology': ['chalmers.se'],
  'university of oslo': ['uio.no'],
  'norwegian university of science and technology': ['ntnu.no'],
  'university of bergen': ['uib.no'],
  'university of helsinki': ['helsinki.fi'],
  'aalto university': ['aalto.fi'],
  'university of turku': ['utu.fi'],
  'tampere university': ['tuni.fi'],
  'university of amsterdam': ['uva.nl'],
  'delft university of technology': ['tudelft.nl'],
  'leiden university': ['universiteitleiden.nl', 'leidenuniv.nl'],
  'utrecht university': ['uu.nl'],
  'eindhoven university of technology': ['tue.nl'],
  'vrije universiteit amsterdam': ['vu.nl'],
  'erasmus university rotterdam': ['eur.nl'],
  'maastricht university': ['maastrichtuniversity.nl'],
  'radboud university': ['ru.nl'],
  'ku leuven': ['kuleuven.be'],
  'ghent university': ['ugent.be'],
  'université catholique de louvain': ['uclouvain.be'],
  'ludwig maximilian university of munich': ['lmu.de'],
  'lmu munich': ['lmu.de'],
  'technical university of munich': ['tum.de'],
  'technische universität münchen': ['tum.de'],
  'heidelberg university': ['uni-heidelberg.de'],
  'humboldt university of berlin': ['hu-berlin.de'],
  'free university of berlin': ['fu-berlin.de'],
  'technical university of berlin': ['tu-berlin.de'],
  'rwth aachen university': ['rwth-aachen.de'],
  'karlsruhe institute of technology': ['kit.edu'],
  'university of freiburg': ['uni-freiburg.de'],
  'university of tübingen': ['uni-tuebingen.de'],
  'university of göttingen': ['uni-goettingen.de'],
  'university of bonn': ['uni-bonn.de'],
  'university of hamburg': ['uni-hamburg.de'],
  'university of cologne': ['uni-koeln.de'],
  'university of mannheim': ['uni-mannheim.de'],
  'university of stuttgart': ['uni-stuttgart.de'],
  'technische universität dresden': ['tu-dresden.de'],
  'justus liebig university giessen': ['uni-giessen.de'],
  'university of vienna': ['univie.ac.at'],
  'tu wien': ['tuwien.ac.at'],
  'epfl': ['epfl.ch'],
  'university of zurich': ['uzh.ch'],
  'university of bern': ['unibe.ch'],
  'university of lausanne': ['unil.ch'],
  'university of geneva': ['unige.ch'],
  'university of basel': ['unibas.ch'],
  'sorbonne university': ['sorbonne-universite.fr'],
  'université paris saclay': ['universite-paris-saclay.fr'],
  'psl university': ['psl.eu'],
  'ecole polytechnique': ['polytechnique.edu'],
  'sciences po': ['sciencespo.fr'],
  'hec paris': ['hec.edu'],
  'insead': ['insead.edu'],

  // Southern and Eastern Europe
  'sapienza university of rome': ['uniroma1.it'],
  'bocconi university': ['unibocconi.it'],
  'university of trento': ['unitn.it'],
  'university of pisa': ['unipi.it'],
  'scuola normale superiore': ['sns.it'],
  'university of barcelona': ['ub.edu'],
  'universitat pompeu fabra': ['upf.edu'],
  'university of navarra': ['unav.edu'],
  'ie university': ['ie.edu'],
  'universidad autónoma de madrid': ['uam.es'],
  'university of lisbon': ['ulisboa.pt'],
  'university of porto': ['up.pt'],
  'university of coimbra': ['uc.pt'],
  'charles university': ['cuni.cz'],
  'czech technical university in prague': ['cvut.cz'],
  'jagiellonian university': ['uj.edu.pl'],
  'university of warsaw': ['uw.edu.pl'],
  'warsaw university of technology': ['pw.edu.pl'],
  'lomonosov moscow state university': ['msu.ru'],
  'saint petersburg state university': ['spbu.ru'],
  'higher school of economics': ['hse.ru'],
  'national technical university of athens': ['ntua.gr'],
  'national and kapodistrian university of athens': ['uoa.gr'],
  'aristotle university of thessaloniki': ['auth.gr'],

  // Türkiye and Israel
  'bogazici university': ['boun.edu.tr'],
  'boğaziçi university': ['boun.edu.tr'],
  'koc university': ['ku.edu.tr'],
  'koç university': ['ku.edu.tr'],
  'ankara university': ['ankara.edu.tr'],
  'istanbul university': ['istanbul.edu.tr'],
  'ibn haldun university': ['ihu.edu.tr'],
  'okan university': ['okan.edu.tr'],
  'istanbul okan university': ['okan.edu.tr'],
  'tel aviv university': ['tau.ac.il'],
  'hebrew university of jerusalem': ['huji.ac.il'],
  'technion': ['technion.ac.il'],
  'weizmann institute of science': ['weizmann.ac.il'],
  'ben gurion university of the negev': ['bgu.ac.il'],
  'bar ilan university': ['biu.ac.il'],

  // Middle East
  'king saud university': ['ksu.edu.sa'],
  'king abdulaziz university': ['kau.edu.sa'],
  'king fahd university of petroleum and minerals': ['kfupm.edu.sa'],
  'king abdullah university of science and technology': ['kaust.edu.sa'],
  'khalifa university': ['ku.ac.ae'],
  'united arab emirates university': ['uaeu.ac.ae'],
  'american university of sharjah': ['aus.edu'],
  'american university in dubai': ['aud.edu'],
  'zayed university': ['zu.ac.ae'],
  'qatar university': ['qu.edu.qa'],
  'sultan qaboos university': ['squ.edu.om'],
  'kuwait university': ['ku.edu.kw'],
  'american university in cairo': ['aucegypt.edu'],
  'cairo university': ['cu.edu.eg'],
  'university of jordan': ['ju.edu.jo'],
  'university of tehran': ['ut.ac.ir'],
  'sharif university of technology': ['sharif.edu'],
  'amirkabir university of technology': ['aut.ac.ir'],

  // Africa
  'university of cape town': ['uct.ac.za'],
  'university of the witwatersrand': ['wits.ac.za'],
  'stellenbosch university': ['sun.ac.za'],
  'university of pretoria': ['up.ac.za'],
  'university of johannesburg': ['uj.ac.za'],
  'university of kwazulu natal': ['ukzn.ac.za'],
  'university of nairobi': ['uonbi.ac.ke'],
  'makerere university': ['mak.ac.ug'],
  'university of ghana': ['ug.edu.gh'],
  'university of lagos': ['unilag.edu.ng'],
  'university of ibadan': ['ui.edu.ng'],
  'addis ababa university': ['aau.edu.et'],
  'university of dar es salaam': ['udsm.ac.tz'],
  'cheikh anta diop university': ['ucad.sn'],
  'mohammed vi polytechnic university': ['um6p.ma'],

  // China, Hong Kong, Taiwan
  'peking university': ['pku.edu.cn'],
  'fudan university': ['fudan.edu.cn'],
  'shanghai jiao tong university': ['sjtu.edu.cn'],
  'zhejiang university': ['zju.edu.cn'],
  'university of science and technology of china': ['ustc.edu.cn'],
  'nanjing university': ['nju.edu.cn'],
  'wuhan university': ['whu.edu.cn'],
  'sun yat sen university': ['sysu.edu.cn'],
  'harbin institute of technology': ['hit.edu.cn'],
  'tongji university': ['tongji.edu.cn'],
  'huazhong university of science and technology': ['hust.edu.cn'],
  "xi'an jiaotong university": ['xjtu.edu.cn'],
  'beihang university': ['buaa.edu.cn'],
  'beijing institute of technology': ['bit.edu.cn'],
  'renmin university of china': ['ruc.edu.cn'],
  'southern university of science and technology': ['sustech.edu.cn'],
  'university of hong kong': ['hku.hk'],
  'chinese university of hong kong': ['cuhk.edu.hk'],
  'hong kong university of science and technology': ['ust.hk'],
  'city university of hong kong': ['cityu.edu.hk'],
  'hong kong polytechnic university': ['polyu.edu.hk'],
  'national taiwan university': ['ntu.edu.tw'],
  'national tsing hua university': ['nthu.edu.tw'],
  'national yang ming chiao tung university': ['nycu.edu.tw'],


  // Bahçeşehir University (Istanbul, Türkiye)
  'bahçeşehir university': ['bau.edu.tr'],
  'bahcesehir university': ['bau.edu.tr'],
  'istanbul bahçeşehir university': ['bau.edu.tr'],
  'istanbul bahcesehir university': ['bau.edu.tr'],
  // Japan and Korea
  'university of tokyo': ['u-tokyo.ac.jp'],
  'kyoto university': ['kyoto-u.ac.jp'],
  'osaka university': ['osaka-u.ac.jp'],
  'tohoku university': ['tohoku.ac.jp'],
  'nagoya university': ['nagoya-u.ac.jp'],
  'kyushu university': ['kyushu-u.ac.jp'],
  'hokkaido university': ['hokudai.ac.jp'],
  'tokyo institute of technology': ['titech.ac.jp', 'isct.ac.jp'],
  'institute of science tokyo': ['isct.ac.jp', 'titech.ac.jp'],
  'waseda university': ['waseda.jp'],
  'keio university': ['keio.ac.jp'],
  'tokushima university': ['tokushima-u.ac.jp'],
  'yamagata university': ['yamagata-u.ac.jp'],
  'yamaguchi university': ['yamaguchi-u.ac.jp'],
  'university of yamanashi': ['yamanashi.ac.jp'],
  'seoul national university': ['snu.ac.kr'],
  'kaist': ['kaist.ac.kr'],
  'korea university': ['korea.ac.kr'],
  'yonsei university': ['yonsei.ac.kr'],
  'pohang university of science and technology': ['postech.ac.kr'],
  'sungkyunkwan university': ['skku.edu'],
  'hanyang university': ['hanyang.ac.kr'],

  // Southeast and Central Asia
  'nanyang technological university': ['ntu.edu.sg'],
  'singapore management university': ['smu.edu.sg'],
  'chulalongkorn university': ['chula.ac.th'],
  'thammasat university': ['tu.ac.th'],
  'chiang mai university': ['cmu.ac.th'],
  'university of the philippines': ['up.edu.ph'],
  'ateneo de manila university': ['ateneo.edu'],
  'vietnam national university hanoi': ['vnu.edu.vn'],
  'hanoi university of science and technology': ['hust.edu.vn'],
  'universiti teknologi malaysia': ['utm.my'],
  'universiti sains malaysia': ['usm.my'],
  "taylor's university": ['taylors.edu.my'],
  'nazarbayev university': ['nu.edu.kz'],
  'al-farabi kazakh national university': ['kaznu.kz'],

  // South Asia
  'indian institute of science': ['iisc.ac.in'],
  'indian institute of technology bombay': ['iitb.ac.in'],
  'indian institute of technology delhi': ['iitd.ac.in'],
  'indian institute of technology madras': ['iitm.ac.in'],
  'indian institute of technology kanpur': ['iitk.ac.in'],
  'indian institute of technology kharagpur': ['iitkgp.ac.in'],
  'indian institute of technology roorkee': ['iitr.ac.in'],
  'indian institute of technology guwahati': ['iitg.ac.in'],
  'indian institute of technology hyderabad': ['iith.ac.in'],
  'university of delhi': ['du.ac.in'],
  'jawaharlal nehru university': ['jnu.ac.in'],
  'banaras hindu university': ['bhu.ac.in'],
  'aligarh muslim university': ['amu.ac.in'],
  'anna university': ['annauniv.edu'],
  'birla institute of technology and science': ['bits-pilani.ac.in'],
  'bangladesh university of engineering and technology': ['buet.ac.bd'],
  'university of dhaka': ['du.ac.bd'],
  'north south university': ['northsouth.edu'],
  'brac university': ['bracu.ac.bd'],
  'university of moratuwa': ['uom.lk'],
  'tribhuvan university': ['tu.edu.np'],
  'kathmandu university': ['ku.edu.np'],

  // Pakistan
  'lahore university of management sciences': ['lums.edu.pk'],
  'national university of sciences and technology': ['nust.edu.pk'],
  'quaid-i-azam university': ['qau.edu.pk'],
  'aga khan university': ['aku.edu'],
  'university of the punjab': ['pu.edu.pk'],
  'university of karachi': ['uok.edu.pk'],
  'comsats university islamabad': ['comsats.edu.pk'],
  'university of engineering and technology lahore': ['uet.edu.pk'],
  'institute of business administration karachi': ['iba.edu.pk'],
  'university of agriculture faisalabad': ['uaf.edu.pk'],
  'government college university lahore': ['gcu.edu.pk'],
  'dow university of health sciences': ['duhs.edu.pk'],
  'bahria university': ['bahria.edu.pk'],
  'air university': ['au.edu.pk'],
  'national university of computer and emerging sciences': ['nu.edu.pk'],
  'university of sialkot': ['uskt.edu.pk'],
  'grand asian university sialkot': ['gaus.edu.pk'],
  'habib university': ['habib.edu.pk'],
  'sukkur iba university': ['iba-suk.edu.pk'],
  'university of management and technology': ['umt.edu.pk'],
  'riphah international university': ['riphah.edu.pk'],
  'university of gujrat': ['uog.edu.pk'],
  'university of sargodha': ['uos.edu.pk'],
  'bahauddin zakariya university': ['bzu.edu.pk'],
  'pakistan institute of engineering and applied sciences': ['pieas.edu.pk'],
  'national university of modern languages': ['numl.edu.pk'],
  'international islamic university islamabad': ['iiu.edu.pk'],
  'university of health sciences lahore': ['uhs.edu.pk'],
  'king edward medical university': ['kemu.edu.pk'],
  'university of veterinary and animal sciences': ['uvas.edu.pk'],

  // Australia and New Zealand
  'australian national university': ['anu.edu.au'],
  'university of sydney': ['sydney.edu.au'],
  'university of new south wales': ['unsw.edu.au'],
  'monash university': ['monash.edu'],
  'university of queensland': ['uq.edu.au'],
  'university of western australia': ['uwa.edu.au'],
  'university of adelaide': ['adelaide.edu.au'],
  'university of technology sydney': ['uts.edu.au'],
  'rmit university': ['rmit.edu.au'],
  'macquarie university': ['mq.edu.au'],
  'deakin university': ['deakin.edu.au'],
  'queensland university of technology': ['qut.edu.au'],
  'curtin university': ['curtin.edu.au'],
  'griffith university': ['griffith.edu.au'],
  'la trobe university': ['latrobe.edu.au'],
  'university of newcastle': ['newcastle.edu.au'],
  'university of wollongong': ['uow.edu.au'],
  'swinburne university of technology': ['swin.edu.au'],
  'james cook university': ['jcu.edu.au'],
  'flinders university': ['flinders.edu.au'],
  'university of south australia': ['unisa.edu.au'],
  'university of tasmania': ['utas.edu.au'],
  'university of auckland': ['auckland.ac.nz'],
  'university of otago': ['otago.ac.nz'],
  'victoria university of wellington': ['wgtn.ac.nz', 'vuw.ac.nz'],
  'massey university': ['massey.ac.nz'],
  'auckland university of technology': ['aut.ac.nz'],
  'university of waikato': ['waikato.ac.nz'],
  'university of canterbury': ['canterbury.ac.nz'],

  // Latin America
  'universidad de buenos aires': ['uba.ar'],
  'universidad de chile': ['uchile.cl'],
  'instituto politécnico nacional': ['ipn.mx'],
  'universidade estadual paulista': ['unesp.br'],
  'universidade federal do rio de janeiro': ['ufrj.br'],
  'universidade federal de minas gerais': ['ufmg.br'],
  'universidad de la república': ['udelar.edu.uy'],
  'pontificia universidad católica del perú': ['pucp.edu.pe'],
  'universidad nacional mayor de san marcos': ['unmsm.edu.pe'],
  'universidad de costa rica': ['ucr.ac.cr'],
  'universidad san francisco de quito': ['usfq.edu.ec'],
  // UI GreenMetric 2025, ranks 1 to 100
  'wageningen university & research': ['wageningenur.nl'],
  'university college cork': ['ucc.ie'],
  'nottingham trent university': ['ntu.ac.uk'],
  'umwelt-campus birkenfeld (trier university of applied sciences)': ['umwelt-campus.de'],
  'universidade de sao paulo usp': ['usp.br'],
  'university of groningen': ['rug.nl'],
  'university of california, davis': ['ucdavis.edu'],
  'university of connecticut': ['uconn.edu'],
  'universita di bologna': ['unibo.it'],
  'universitat bremen': ['uni-bremen.de'],
  'universidad autónoma de nuevo león': ['uanl.mx'],
  'luiss university': ['luiss.edu'],
  'university of turin': ['unito.it'],
  'university of limerick': ['ul.ie'],
  'université de sherbrooke': ['usherbrooke.ca'],
  'dublin city university': ['dcu.ie'],
  'hame university of applied sciences': ['hamk.fi'],
  'politecnico di torino': ['polito.it'],
  'universitas indonesia': ['ui.ac.id'],
  'rudn university': ['rudn.ru'],
  'national pingtung university of science & technology': ['npust.edu.tw'],
  'kasetsart university': ['ku.ac.th'],
  'universitas diponegoro': ['undip.ac.id'],
  'universidad del rosario': ['urosario.edu.co'],
  'istanbul technical university': ['itu.edu.tr'],
  'universitas gadjah mada': ['ugm.ac.id'],
  'federal university of lavras': ['ufla.br'],
  'universitas negeri semarang': ['unnes.ac.id'],
  'university of pécs': ['pte.hu'],
  'national chi nan university': ['ncnu.edu.tw'],
  'universiti putra malaysia': ['upm.edu.my'],
  "universita degli studi dell'aquila": ['univaq.it'],
  'ipb university': ['ipb.ac.id'],
  'universiti malaya': ['um.edu.my'],
  'mahidol university': ['mahidol.ac.th'],
  'aalborg university': ['aau.dk'],
  'da-yeh university': ['dyu.edu.tw'],
  'university of sharjah': ['sharjah.ac.ae'],
  'universitas sebelas maret': ['uns.ac.id'],
  'universiti malaysia pahang al- sultan abdullah': ['ump.edu.my'],
  'university of szeged': ['u-szeged.hu'],
  'al-balqa applied university': ['bau.edu.jo'],
  'national yunlin university of science & technology': ['yuntech.edu.tw'],
  'universitas airlangga': ['unair.ac.id'],
  'tunghai university': ['thu.edu.tw'],
  'universidad de santander': ['udes.edu.co'],
  'weifang institute of technology': ['wfust.edu.cn'],
  'yildiz technical university': ['yildiz.edu.tr'],
  'chaoyang university of technology': ['cyut.edu.tw'],
  'siberian federal university': ['sfu-kras.ru'],
  'universidad autónoma de occidente': ['uao.edu.co'],
  'benemérita universidad autónoma de puebla': ['buap.mx'],
  'institut teknologi bandung': ['itb.ac.id'],
  'siam university': ['siam.edu'],
  'cyprus international university': ['ciu.edu.tr'],
  'universitas padjadjaran': ['unpad.ac.id'],
  'riga technical university': ['rtu.lv'],
  'national taitung university': ['nttu.edu.tw'],
  'universitas islam negeri raden intan lampung': ['radenintan.ac.id'],
  'universidade federal de mato grosso do sul': ['ufms.br'],
  'qassim university': ['qu.edu.sa'],
  'telkom university': ['telkomuniversity.ac.id'],
  'universidad de granada': ['ugr.es'],
  'instituto federal de educacao, ciencia e tecnologia do sul de minas gerais': ['ifsuldeminas.edu.br'],
  'institut teknologi sumatera': ['itera.ac.id'],
  'erciyes university': ['erciyes.edu.tr'],
  'institut teknologi sepuluh nopember': ['its.ac.id'],
  'czech university of life sciences prague': ['czu.cz'],
  "king mongkut's university of technology thonburi": ['kmutt.ac.th'],
  'national chin-yi university of technology': ['ncut.edu.tw'],
  'suranaree university of technology': ['sut.ac.th'],
  'national cheng kung university': ['ncku.edu.tw'],
  'university of eastern finland': ['uef.fi'],
  'universidad complutense de madrid': ['ucm.es'],
  'universiti malaysia sabah': ['ums.edu.my'],
  'ton duc thang university': ['tdt.edu.vn'],
  'universidad nacional de colombia': ['unal.edu.co'],
  'lincoln university': ['lincoln.ac.nz', 'lincoln.edu', 'lincolnu.edu'],
  'universidad el bosque': ['uelbosque.edu.co'],
  'universidad de los andes colombia': ['uniandes.edu.co'],
  'university of campinas': ['unicamp.br'],
  'universidad pontificia bolivariana': ['upb.edu.co'],
  'ege university': ['ege.edu.tr'],
  'walailak university': ['wu.ac.th'],
  'universitas hasanuddin': ['unhas.ac.id'],
  'universidad nacional autónoma de méxico': ['unam.mx'],
  'universitas sultan ageng tirtayasa': ['untirta.ac.id'],
  'universitas lampung': ['unila.ac.id'],
  'ozyegin university': ['ozyegin.edu.tr'],
  'universitas islam indonesia': ['uii.ac.id'],
  'yeditepe university': ['yeditepe.edu.tr'],
  'politecnico di milano': ['polimi.it'],
  'mahasarakham university': ['msu.ac.th'],
  'uitm shah alam': ['uitm.edu.my'],
  'universitas negeri yogyakarta': ['uny.ac.id'],
  'universita politecnica delle marche': ['univpm.it'],
  'california state university, sacramento': ['csus.edu'],
  'universiti pendidikan sultan idris': ['upsi.edu.my'],
  'university of sopron': ['uni-sopron.hu'],
  'ontario tech university': ['uoit.ca'],

  // UI GreenMetric 2025, ranks 101 to 200
  'baskent university': ['baskent.edu.tr'],
  'universitas muhammadiyah malang': ['umm.ac.id'],
  'middle east technical university': ['metu.edu.tr'],
  'universiti teknikal malaysia melaka': ['utem.edu.my'],
  'national pingtung university': ['nptu.edu.tw'],
  'universitas brawijaya': ['ub.ac.id'],
  'masaryk university': ['muni.cz'],
  'an-najah national university': ['najah.edu'],
  'university of phayao': ['up.ac.th'],
  'university of camerino': ['unicam.it'],
  'university of milano-bicocca': ['unimib.it'],
  'de la salle university - dasmarinas': ['dlsud.edu.ph'],
  'universitas teuku umar': ['utu.ac.id'],
  'university of babylon': ['uobabylon.edu.iq'],
  'imam abdulrahman bin faisal university': ['iau.edu.sa'],
  'jordan university of science and technology': ['just.edu.jo'],
  'manipal academy of higher education': ['manipal.edu'],
  'chettinad academy of research and education': ['chettinadhealthcity.com'],
  'american university of beirut': ['aub.edu.lb'],
  'valaya alongkorn rajabhat university under the royal patronage': ['vru.ac.th'],
  'universitas medan area': ['uma.ac.id'],
  'universidad de antioquia': ['udea.edu.co'],
  'izmir institute of technology': ['iyte.edu.tr'],
  'sunway university': ['sunway.edu.my'],
  'national chiayi university': ['ncyu.edu.tw'],
  'universitas multimedia nusantara': ['umn.ac.id'],
  'mangalore university': ['mangaloreuniversity.ac.in'],
  'universidad tecnologica ecotec': ['ecotec.edu.ec'],
  'universidad eafit': ['eafit.edu.co'],
  'gdańsk university of technology': ['pg.gda.pl'],
  'ubon ratchathani university': ['ubu.ac.th'],
  'providence university': ['pu.edu.tw'],
  'universitas muhammadiyah yogyakarta': ['umy.ac.id'],
  'universidad politécnica estatal del carchi': ['upec.edu.ec'],
  'inonu university malatya': ['inonu.edu.tr'],
  's r m university (institute of science and technology)': ['srmuniv.ac.in'],
  'universitat autònoma de barcelona': ['uab.es'],
  'universidad iberoamericana puebla': ['iberopuebla.mx'],
  'd. serikbayev east kazakhstan technical university': ['ektu.kz'],
  'escuela superior politecnica del litoral': ['espol.edu.ec'],
  'the university of lahore': ['uol.edu.pk'],
  'university of anbar': ['uoanbar.edu.iq'],
  'universidade do vale do taquari - univates': ['univates.br'],
  'khwaja fareed university of engineering and information technology': ['kfueit.edu.pk'],
  'muhammad nawaz shareef university of agriculture, multan pakistan': ['mnsuam.edu.pk'],
  'jadara university': ['jadara.edu.jo'],
  'razi university kermanshah': ['razi.ac.ir'],
  'universidade do minho': ['uminho.pt'],
  'universiti sultan zainal abidin': ['unisza.edu.my'],
  'naresuan university': ['nu.ac.th'],
  'universiti tun hussein onn malaysia': ['uthm.edu.my'],
  'nova university lisbon': ['unl.pt'],
  'universitas pancasila': ['univpancasila.ac.id'],
  'national university of kaohsiung': ['nuk.edu.tw'],
  'dhurakij pundit university': ['dpu.ac.th'],
  'instituto politecnico de viana do castelo': ['ipvc.pt'],
  'sakarya üniversitesi': ['sakarya.edu.tr'],
  'bashkir state agrarian university': ['bsau.ru'],
  'universitas negeri malang': ['um.ac.id'],
  'sabanci university': ['sabanciuniv.edu'],
  'pibulsongkram rajabhat university': ['psru.ac.th'],
  'irkutsk national research technical university': ['istu.edu'],
  'universidad panamericana': ['up.edu.mx'],
  'universitas negeri surabaya': ['unesa.ac.id'],
  'tarbiat modares university': ['modares.ac.ir'],
  'al-mustaqbal university': ['mustaqbal-college.edu.iq'],
  'princess nourah bint abdulrahman university': ['pnu.edu.sa'],
  'international university of business agriculture and technology': ['iubat.edu'],
  'dokuz eylul university': ['deu.edu.tr'],
  'bartin university': ['bartin.edu.tr'],
  'alexandria university': ['alexu.edu.eg'],
  'immanuel kant baltic federal university': ['kantiana.ru'],
  'tra vinh university': ['tvu.edu.vn'],
  'slovak university of agriculture in nitra': ['uniag.sk'],
  'cukurova university': ['cu.edu.tr'],
  'american university of the middle east (aum)': ['aum.edu.kw'],
  'kutahya dumlupinar university': ['dpu.edu.tr'],
  'hochschule anhalt': ['hs-anhalt.de'],
  'king faisal university': ['kfu.edu.sa'],
  'atatürk üniversitesi': ['atauni.edu.tr'],
  'tashkent state university of law': ['tsul.uz'],
  'tokat gaziosmanpasa university': ['gop.edu.tr'],
  'hacettepe university': ['hacettepe.edu.tr', 'hun.edu.tr'],
  'trakya university': ['trakya.edu.tr'],
  'düzce university': ['duzce.edu.tr'],
  'university of peradeniya': ['pdn.ac.lk'],
  'universidad tecnologica de pereira': ['utp.edu.co'],
  'universidad eia': ['eia.edu.co'],
  'university of kelaniya': ['kln.ac.lk'],
  'nanhua university taiwan': ['nhu.edu.tw'],
  'national institute of technology silchar': ['nits.ac.in'],
  'silpakorn university': ['su.ac.th'],
  'universitas halu oleo': ['uho.ac.id'],
  'thaksin university': ['tsu.ac.th'],
  'mae fah luang university': ['mfu.ac.th'],
  'senac university center': ['senac.br'],
  'al-furat al-awsat technical university': ['atu.edu.iq'],
  'universita degli studi di padova': ['unipd.it'],
  'politeknik merlimau melaka': ['mypoliteknik.edu.my'],
  'mariano marcos state university': ['mmsu.edu.ph'],

  // UI GreenMetric 2025, ranks 201 to 300
  'hasan kalyoncu university': ['hku.edu.tr'],
  'mersin university': ['mersin.edu.tr'],
  'universitas esa unggul': ['esaunggul.ac.id'],
  'universiti malaysia terengganu (umt)': ['umt.edu.my'],
  'universidad iberoamericana torreón': ['iberotorreon.edu.mx'],
  'saveetha institute of medical and technical sciences': ['saveetha.com'],
  'cetys university (centro de ensenanza tecnica y superior)': ['cetys.mx'],
  'huachiew chalermprakiet university': ['hcu.ac.th'],
  'alzahra university': ['alzahra.ac.ir'],
  'universidad de la sabana': ['unisabana.edu.co'],
  'università degli studi della tuscia': ['unitus.it'],
  'università degli studi di firenze': ['unifi.it'],
  'university of kashan': ['kashanu.ac.ir'],
  'firat university': ['firat.edu.tr'],
  'northeastern university': ['northeastern.edu', 'neu.ac.th'],
  'university of baghdad': ['uobaghdad.edu.iq'],
  'kastamonu university': ['kastamonu.edu.tr'],
  'shinshu university': ['shinshu-u.ac.jp'],
  'institución universitaria politecnico grancolombiano': ['poli.edu.co'],
  'rajamangala university of technology thanyaburi (rmutt)': ['rmutt.ac.th'],
  'universiti selangor': ['unisel.edu.my'],
  'centro universitário facens': ['facens.br'],
  'kun shan university': ['ksu.edu.tw'],
  'ondokuz mayis university': ['omu.edu.tr'],
  'fundación universidad del norte barranquilla': ['uninorte.edu.co'],
  'universita degli studi di milano la statale': ['unimi.it'],
  'mardin artuklu üniversitesi': ['artuklu.edu.tr'],
  'universidad surcolombiana': ['usco.edu.co'],
  'universiti tunku abdul rahman': ['utar.edu.my'],
  'pontificia universidad javeriana cali': ['javerianacali.edu.co'],
  'university of passau': ['uni-passau.de'],
  'iteso, universidad jesuita de guadalajara': ['iteso.mx'],
  'universidade de sorocaba': ['uniso.br'],
  'kalasalingam academy of research and education': ['kalasalingam.ac.in'],
  'ziauddin university': ['zu.edu.pk'],
  'university of petra': ['uop.edu.jo'],
  'universitas islam negeri raden fatah palembang': ['radenfatah.ac.id'],
  'universitas islam negeri syarif hidayatullah jakarta': ['uinjkt.ac.id'],
  'batangas state university, the national engineering university': ['batstate-u.edu.ph'],
  'universidad politecnica de valencia': ['upv.es'],
  'tecnologico de monterrey': ['tec.mx', 'itesm.mx', 'itesm.edu'],
  'maejo university': ['mju.ac.th'],
  'universitas syiah kuala': ['unsyiah.ac.id'],
  'binus university': ['binus.ac.id'],
  'kutahya health sciences university': ['ksbu.edu.tr'],
  'university of information technology and management in rzeszow': ['wsiz.rzeszow.pl'],
  'vytautas magnus university': ['vdu.lt'],
  'university of kerbala': ['uokerbala.edu.iq'],
  'universidad de salamanca': ['usal.es'],
  'russian biotechnological university': ['mgupp.ru'],
  'universiti malaysia kelantan (umk)': ['umk.edu.my'],
  'university of central punjab': ['ucp.edu.pk'],
  'universiti kebangsaan malaysia': ['ukm.my'],
  'niğde ömer halisdemir university': ['ohu.edu.tr'],
  'university of alkafeel': ['alkafeel.edu.iq'],
  'universidad icesi': ['icesi.edu.co'],
  'ghulam ishaq khan institute of engineering sciences and technology': ['giki.edu.pk'],
  'm. auezov south kazakhstan research university': ['auezov.edu.kz'],
  'universidad de caldas': ['ucaldas.edu.co'],
  'october 6 university': ['o6u.edu.eg'],
  'gitam : gandhi institute of technology and management': ['gitam.edu'],
  'universidade de vigo': ['uvigo.es'],
  'benha university': ['bu.edu.eg'],
  'daffodil international university': ['daffodilvarsity.edu.bd'],
  'al-zaytoonah university of jordan': ['zuj.edu.jo'],
  'università degli studi di urbino carlo bo': ['uniurb.it'],
  'universitas terbuka': ['ut.ac.id'],
  'istanbul aydin university': ['aydin.edu.tr'],
  'universidad santo tomas': ['usta.edu.co'],
  'universitas ahmad dahlan': ['uad.ac.id'],
  'università degli studi di genova': ['unige.it'],
  'universitas sumatera utara': ['usu.ac.id'],
  'universidad de alcalá': ['uah.es'],
  'capital university of science and technology': ['cust.edu.pk'],
  'rajamangala university of technology isan': ['rmuti.ac.th'],
  'universitas katolik indonesia atma jaya': ['atmajaya.ac.id'],
  'allama iqbal open university': ['aiou.edu.pk'],
  'university of bahrain': ['uob.edu.bh'],
  'pontificia universidad catolica de chile': ['uc.cl'],
  'universitat de girona': ['udg.edu'],
  'adam mickiewicz university, poznan': ['amu.edu.pl'],
  'universidade de aveiro': ['ua.pt'],
  'universidad iberoamericana ciudad de méxico': ['uia.mx'],
  'chang jung christian university': ['cjcu.edu.tw'],
  'babes bolyai university': ['ubbcluj.ro'],
  'universita degli studi della basilicata': ['unibas.it'],
  'università degli studi di salerno': ['unisa.it'],
  'zonguldak bulent ecevit university': ['beun.edu.tr'],
  'kocaeli university': ['kocaeli.edu.tr'],
  'tzu chi university': ['tcu.edu.tw'],
  'university of warith al-anbiyaa': ['uowa.edu.iq'],
  "king mongkut's institute of technology ladkrabang": ['kmitl.ac.th'],
  'university of northern philippines': ['unp.edu.ph'],
  'national taipei university of technology': ['ntut.edu.tw'],
  'sohag university': ['sohag-univ.edu.eg'],
  'universitas islam negeri jurai siwo lampung': ['metrouniv.ac.id'],
  'nitte (deemed to be university)': ['nitte.edu.in'],
  'iqra university': ['iqra.edu.pk'],

  // UI GreenMetric 2025, ranks 301 to 418
  'hatyai university': ['hu.ac.th'],
  'afyon kocatepe university': ['aku.edu.tr'],
  'universidade de santiago de compostela': ['usc.es'],
  'northern technical university': ['ntu.edu.iq'],
  'pontificia universidad javeriana-bogota': ['javeriana.edu.co'],
  'oguz han engineering and technology university of turkmenistan': ['etut.edu.tm'],
  'universiti malaysia perlis': ['unimap.edu.my'],
  'tarlac agricultural university': ['tca.edu.ph'],
  "king mongkut's university of technology north bangkok": ['kmutnb.ac.th'],
  'university of west attica': ['uniwa.gr'],
  'universidad autónoma del estado de mexico': ['uaemex.mx'],
  'palestine technical university - kadoorie': ['ptuk.edu.ps'],
  'open university of sri lanka': ['ou.ac.lk'],
  'ryazan state medical university': ['rzgmu.ru'],
  'kamphaeng phet rajabhat university': ['kpru.ac.th'],
  'prince of songkla university': ['psu.ac.th'],
  'universidad catolica andres bello': ['ucab.edu.ve'],
  'khon kaen university': ['kku.ac.th'],
  'universidade estadual de maringá': ['uem.br'],
  'ming chi university of technology': ['mcut.edu.tw'],
  'universidad metropolitana caracas': ['unimet.edu.ve'],
  'volgograd state university': ['volsu.ru'],
  'hungkuang university': ['hk.edu.tw'],
  'sri sri university': ['srisriuniversity.edu.in'],
  'the university of faisalabad': ['tuf.edu.pk'],
  'universidad catolica de cordoba': ['ucc.edu.ar'],
  'fergana state university': ['fdu.uz'],
  'universitas teknokrat indonesia': ['teknokrat.ac.id'],
  'canakkale onsekiz mart university': ['comu.edu.tr'],
  'universitas pelita harapan': ['uph.edu'],
  'kolej komuniti jerantut': ['kkjerantut.mypolycc.edu.my'],
  'derzhavin tambov state university': ['tsutmb.ru'],
  'yessenov university': ['yu.edu.kz'],
  'abu dhabi university': ['adu.ac.ae'],
  "alisher navo'i tashkent state university of uzbek language and literature": ['tsuull.uz'],
  'universidade de passo fundo': ['upf.br'],
  'institución universitaria colegio mayor de antioquia': ['colmayor.edu.co'],
  'universitas sriwijaya': ['unsri.ac.id'],
  'bialystok university of technology': ['pb.edu.pl'],
  'manisa celal bayar university': ['mcbu.edu.tr'],
  'university of gdansk': ['ug.edu.pl'],
  'universitas pembangunan nasional veteran jawa timur': ['upnjatim.ac.id'],
  'ukrainian national forestry university': ['nltu.edu.ua'],
  'cappadocia university': ['kapadokya.edu.tr'],
  'the islamia university of bahawalpur': ['iub.edu.pk'],
  'karunya institute of technology and sciences': ['karunya.edu'],
  'universidade federal fluminense': ['uff.br'],
  'southern leyte state university': ['southernleytestateu.edu.ph'],
  'juraj dobrila university of pula': ['unipu.hr'],
  'universidade federal do triângulo mineiro': ['uftm.edu.br'],
  'sukhothai thammathirat open university': ['stou.ac.th'],
  'university of a coruña': ['udc.es'],
  'politeknik seberang perai': ['psp.edu.my'],
  '2ie international institute for water and environmental engineering': ['2ie-edu.org'],
  'bursa uludag university': ['uludag.edu.tr'],
  'abai kazakh national pedagogical university': ['kaznpu.kz'],
  'seinäjoki university of applied sciences': ['seamk.fi'],
  'bukidnon state university': ['buksu.edu.ph'],
  'universidad del valle': ['univalle.edu.co'],
  'universitas budi luhur': ['budiluhur.ac.id'],
  'samar state university': ['ssu.edu.ph'],
  'urdaneta city university': ['ucu.edu.ph'],
  'universidad rey juan carlos': ['urjc.es'],
  'chitkara university, punjab': ['chitkara.edu.in'],
  'ain shams university': ['asu.edu.eg'],
  'new mansoura university': ['nmu.edu.eg'],
  'bansomdejchaopraya rajabhat university': ['bsru.ac.th'],
  'politeknik sultan idris shah': ['psis.edu.my'],
  'universita degli studi di cagliari': ['unica.it'],
  'university of colombo': ['cmb.ac.lk'],
  'instituto tecnologico metropolitano': ['itm.edu.co'],
  'beni-suef university': ['bsu.edu.eg'],
  'politeknik mukah': ['pmu.edu.my'],
  'vsb - technical university of ostrava': ['vsb.cz'],
  'mangalayatan university jabalpur': ['mangalayatan.co.in'],
  'jamia millia islamia': ['jmi.ac.in'],
  'bilkent university': ['bilkent.edu.tr'],
  'universidade federal de vicosa - ufv': ['ufv.br'],
  'universitas pendidikan indonesia': ['upi.edu'],
  'perm national research polytechnic university': ['pstu.ru'],
  'hitit university': ['hitit.edu.tr'],
  'sumy state university': ['sumdu.edu.ua'],
  'burapha university': ['buu.ac.th'],
  'phranakhon si ayutthaya rajabhat university': ['aru.ac.th'],
  'rajamangala university of technology suvarnabhumi': ['rmutsb.ac.th'],
  'mugla sitki kocman university': ['mu.edu.tr'],
  'university of kirkuk': ['uokirkuk.edu.iq'],
  'osmaniye korkut ata university': ['osmaniye.edu.tr'],
  'can tho university of medicine and pharmacy': ['ctump.edu.vn'],
  'universitas kristen krida wacana': ['ukrida.ac.id'],
  'pangasinan state university': ['psu.edu.ph'],
  'metropolitan autonomous university, uam': ['uam.mx'],
  'integral university': ['integraluniversity.ac.in'],
  'jizzakh polytechnic institute': ['jizpi.uz'],
  'universidad ces': ['ces.edu.co'],
  'national skills university islamabad': ['nsu.edu.pk'],
  'universidad de ciencias aplicadas y ambientales udca': ['udca.edu.co'],
  'universitas aisyiyah yogyakarta': ['unisayogya.ac.id'],
  'euromed university of fes': ['ueuromed.org'],
  'eötvös loránd university budapest': ['elte.hu'],
  'bukhara state university': ['buxdu.uz'],
  'universitas katolik parahyangan': ['unpar.ac.id'],
  'karshi state university': ['qarshidu.uz'],
  'middle east university (meu)': ['meu.edu.jo'],
  'nakhon si thammarat rajabhat university': ['nstru.ac.th'],
  "saint mary's university": ['smu.edu.ph', 'smu.ca'],
  'universidad de jaén': ['ujaen.es'],
  'corvinus university of budapest': ['uni-corvinus.hu'],
  'universita degli studi di parma': ['unipr.it'],
  'loyola university': ['uloyola.es', 'luc.edu', 'loyola.edu', 'loyno.edu'],
  'o.p. jindal university': ['opju.ac.in'],
  'universidad de las américas puebla': ['udlap.mx'],
  'kashan university of medical sciences and health services': ['kaums.ac.ir'],
  'politeknik nilai': ['pns.mypolycc.edu.my'],
  'antalya bilim university': ['antalya.edu.tr'],
  'institute for art & culture': ['iac.edu.pk'],
  'politeknik port dickson': ['polipd.mypolycc.edu.my'],
  'al-zahraa university for women': ['alzahraa.edu.iq'],
};

final RegExp _emailRe =
RegExp(r'[a-z0-9._%+\-]+@([a-z0-9\-]+(?:\.[a-z0-9\-]+)+)');
final RegExp _urlRe = RegExp(r'(?:https?://|www\.)([a-z0-9\-]+(?:\.[a-z0-9\-]+)+)');

bool _domainMatches(String domain, List<String> expected) =>
    expected.any((d) => domain == d || domain.endsWith('.$d'));

/// True when [name] appears in [text] as whole words.
/// Long names also get a spaceless check, because the reader sometimes
/// drops spaces. Short names never do, since they match inside other words.
bool mentionsIssuer(String text, String name) {
  final boundary = RegExp(
    r'(^|[^a-z0-9])' + RegExp.escape(name) + r'($|[^a-z0-9])',
  );
  if (boundary.hasMatch(text)) return true;
  final compactName = name.replaceAll(' ', '');
  if (compactName.length < 16) return false;
  return text.replaceAll(RegExp(r'\s+'), '').contains(compactName);
}

List<Signal> analyzeScamLanguage(String text) {
  final t = text.toLowerCase();
  if (t.trim().length < 40) return const [];

  final out = <Signal>[];
  // 0. Text quality: if most characters are not letters or digits, the
  // reader probably failed and the other checks are unreliable.
  final visible = t.replaceAll(RegExp(r'\s+'), '');
  final lettersAndDigits = RegExp(r'[a-z0-9]').allMatches(visible).length;
  if (visible.isNotEmpty && lettersAndDigits / visible.length < 0.6) {
    out.add(const Signal(
      name: 'Text could not be read clearly',
      suspicion: 0.2,
      weight: 1,
      reason:
      'Much of the text looks garbled, so the checks may miss something. Try a sharper, straighter picture.',
      role: SignalRole.unreadable,
    ));
  }
  final institutional = RegExp(
      r'(university|college|admission|offer letter|scholarship|visa|embassy|bank|ministry|government|employment|job offer|recruit)')
      .hasMatch(t);

  // 1. Payment requests
  final riskyChannel = RegExp(
      r'(western union|moneygram|bitcoin|crypto|usdt|gift card|personal account|binance)')
      .firstMatch(t);
  final feeMention = RegExp(
      r'(application|processing|admission|registration|visa|acceptance|document|courier|verification|clearance|booking|security)\s+(fee|fees|charge|charges|deposit)')
      .hasMatch(t);
  final payMention =
  RegExp(r'\b(pay|payment|transfer|deposit|remit|send)\b').hasMatch(t);
  final bankDetails = RegExp(
      r'(iban|swift|account number|account no|bank transfer|wire transfer)')
      .hasMatch(t);

  if (riskyChannel != null && (feeMention || payMention)) {
    out.add(Signal(
      name: 'Risky payment request',
      suspicion: 0.9,
      weight: 3,
      reason:
      'The text asks for money and mentions "${riskyChannel.group(0)}". Real universities and employers collect '
          'payments through their own official pages, not through money transfer services, crypto, gift cards or personal accounts.',
    ));
  } else if (feeMention && (payMention || bankDetails) && institutional) {
    out.add(const Signal(
      name: 'Fee requested',
      suspicion: 0.6,
      weight: 2,
      reason:
      'The document asks for a fee. Confirm the amount and the payment details only on the official website of the issuer, never from this document alone.',
    ));
  }

  // 2. Pressure
  if (RegExp(
      r'(within\s+(24|48|72)\s*hours|immediately|last chance|deadline (is )?(today|tomorrow)|seats? (are )?limited|act now|expires today)')
      .hasMatch(t)) {
    out.add(const Signal(
      name: 'Pressure to act fast',
      suspicion: 0.5,
      weight: 1.5,
      reason:
      'The text pushes you to act very quickly. Scams use pressure so that you do not stop to verify.',
    ));
  }

  // 3. Promises that are too good
  if (RegExp(
      r'(guaranteed (admission|visa|scholarship|placement|job)|100\s*%\s*(visa|admission|success)|no (ielts|gre|gmat|interview) required|without (an )?(application|ielts|test|interview))')
      .hasMatch(t)) {
    out.add(const Signal(
      name: 'Guaranteed outcome',
      suspicion: 0.7,
      weight: 2,
      reason:
      'The text promises a guaranteed result or skips normal steps such as an application, test or interview. Genuine institutions do not do this.',
    ));
  }

  // 4. Free email address on an official looking letter
  if (institutional &&
      RegExp(r'@(gmail|yahoo|hotmail|outlook|proton|protonmail|icloud|live)\.')
          .hasMatch(t)) {
    out.add(const Signal(
      name: 'Free email address',
      suspicion: 0.5,
      weight: 1.5,
      reason:
      'An official looking document lists a free email address. Organisations normally write from their own domain.',
    ));
  }

  // 5. Chat app contacts
  if (RegExp(r'(whatsapp|telegram|wa\.me|t\.me)').hasMatch(t)) {
    out.add(const Signal(
      name: 'Chat app contact',
      suspicion: 0.4,
      weight: 1.2,
      reason:
      'The document asks you to continue on WhatsApp or Telegram. Official offices rarely handle admissions or offers that way.',
    ));
  }

  // 6. Emails or websites that do not match the named university
  final named = _knownIssuers.entries
      .where((e) => mentionsIssuer(t, e.key))
      .toList();
  if (named.isNotEmpty) {
    final allowed = <String>[for (final e in named) ...e.value];
    final domains = <String>{
      ..._emailRe.allMatches(t).map((m) => m.group(1)!),
      ..._urlRe.allMatches(t).map((m) => m.group(1)!),
    };
    final mismatched =
    domains.where((d) => !_domainMatches(d, allowed)).toList();

    final matched = domains.where((d) => _domainMatches(d, allowed)).toList();

    if (mismatched.isNotEmpty) {
      out.add(Signal(
        name: 'Address does not match the issuer',
        suspicion: 0.8,
        weight: 2.5,
        reason:
        'The document names "${named.first.key}" but lists ${mismatched.take(2).join(' and ')}. '
            'The official domain is ${named.first.value.first}. This can also be a reading error, so check it by hand.',
      ));
    } else if (matched.isNotEmpty) {
      out.add(Signal(
        name: 'Official address found',
        suspicion: 0.0,
        weight: 2,
        reason:
        'The text names "${named.first.key}" and its links or emails use the official domain ${matched.first}. '
            'A scammer can copy a real address, so still confirm on the official website.',
        role: SignalRole.positiveEvidence,
      ));
    }
  }

  // 7. A payment receipt inside an offer letter.
  // The reader sometimes drops spaces between words, so every phrase is also
  // tried without spaces.
  final compact = t.replaceAll(RegExp(r'\s+'), '');
  bool has(String p) =>
      t.contains(p) || compact.contains(p.replaceAll(' ', ''));

  const offerPhrases = [
    'admission offer',
    'offer letter',
    'offered admission',
    'offer of admission',
    'pleased to inform you',
  ];
  const receiptPhrases = [
    'we have received',
    'amount paid',
    'payment status',
    'payment confirmation',
    'fee payment',
    'payment received',
  ];
  if (offerPhrases.any(has) && receiptPhrases.any(has)) {
    out.add(const Signal(
      name: 'Payment receipt inside an offer letter',
      suspicion: 0.75,
      weight: 2.5,
      reason:
      'This offer letter also confirms a payment. Universities issue receipts from their own payment system, '
          'not inside an admission letter. Confirm any payment directly with the university.',
    ));
  }

  // 8. Percentage scholarship claims on a letter from a well known university
  final namesKnownIssuer = named.isNotEmpty;
  if (namesKnownIssuer &&
      RegExp(r'\d{1,3}\s*%\s*(scholarship|tuition|merit|waiver)').hasMatch(t)) {
    out.add(const Signal(
      name: 'Scholarship claim',
      suspicion: 0.5,
      weight: 1.5,
      reason:
      'The letter promises a percentage scholarship. Many top universities do not give percentage merit scholarships, '
          'so confirm this in writing on the official website before you pay anything.',
    ));
  }

  // 9. Repeated words or phrases suggest careless writing or a copied template
  final repeated = RegExp(r'\b(\w{3,})\s+\1\b').firstMatch(t) ??
      RegExp(r'\b(\w{2,}\s+\w{2,})\s+\1\b').firstMatch(t);
  if (repeated != null) {
    out.add(Signal(
      name: 'Repeated words',
      suspicion: 0.4,
      weight: 1,
      reason:
      'The phrase "${repeated.group(1)}" appears twice in a row. Official letters are proofread, so errors like this are a warning sign, '
          'although honest mistakes happen too.',
    ));
  }
  // 10. Social media post: clean wording proves little here.
  if (RegExp(
      r'(\bfacebook\b|\binstagram\b|\bfollowers\b|\bsponsored\b|\bsee more\b|\bwrite a comment\b|\blike\b.{0,20}\bcomment\b.{0,20}\bshare\b)')
      .hasMatch(t)) {
    out.add(const Signal(
      name: 'Social media post',
      suspicion: 0.0,
      weight: 0.1,
      reason:
      'This looks like a social media post. Anyone can post here, so open the organisation\'s own careers or admissions page and look for the same notice.',
      role: SignalRole.socialMedia,
    ));
  }

  // 11. Shortened links hide the real destination.
  final shortLink = RegExp(
      r'\b(bit\.ly|tinyurl\.com|t\.co|goo\.gl|is\.gd|cutt\.ly|rb\.gy|shorturl\.at|ow\.ly|fb\.me)/\S+')
      .firstMatch(t);
  if (shortLink != null) {
    out.add(Signal(
      name: 'Shortened link',
      suspicion: 0.4,
      weight: 1,
      reason:
      'The text contains a shortened link (${shortLink.group(0)}). It hides where the link really goes and cannot be checked offline. Do not open it until you confirm the source.',
    ));
  }

  // 12. Job post patterns
  final jobContext = RegExp(
      r'\b(job|vacancy|vacancies|hiring|we are hiring|position|career|careers|recruitment|apply)\b')
      .hasMatch(t);
  if (jobContext) {
    final jobFlags = <String>[
      if (RegExp(r'(forms\.gle|docs\.google\.com/forms|google form)')
          .hasMatch(t))
        'applications through a Google Form',
      if (RegExp(r'no experience (is )?(needed|required|necessary)')
          .hasMatch(t))
        'no experience needed',
      if (RegExp(
          r'send (your |ur )?(cv|resume).{0,40}(whatsapp|telegram|inbox|\bdm\b)')
          .hasMatch(t))
        'CV sent to a chat app or private message',
      if (RegExp(r'earn .{0,12}\d+.{0,20}(per day|daily|per week|weekly)')
          .hasMatch(t))
        'high daily or weekly earnings promised',
    ];
    if (jobFlags.isNotEmpty) {
      out.add(Signal(
        name: 'Job post warning signs',
        suspicion: 0.55,
        weight: 1.5,
        reason:
        'This job notice has patterns common in fake jobs: ${jobFlags.join(', ')}. Confirm the vacancy on the employer\'s official careers page.',
      ));
    }
  }
  return out;
}
/// Official web domains of a well known institution named in the text,
/// or null when the text names none of them.
List<String>? expectedDomainsFor(String lowerText) {
  final found = <String>{};
  for (final entry in _knownIssuers.entries) {
    if (mentionsIssuer(lowerText, entry.key)) found.addAll(entry.value);
  }
  return found.isEmpty ? null : found.toList();
}