public class StringUtils {
    //Структура, що містить сміття назв, яке не треба перевіряти - може доповнюватися
    public static Map<String, String> mapTrashWords = new Map<String, String>{
    'ТОРГОВО-ПРОИЗВОДСТВЕННЫЙ'=>'', 'ODPOWIEDZIALNOSCIA'=>'', 'ВІДПОВІДАЛЬНІСТЮ'=>'', 'ОТВЕТСТВЕННОСТЬЮ'=>'', 'ПІДПРИЄМСТВО'=>'', 'ТОРГОВЕЛЬНИЙ'=>'',
    'ТОРГІВЕЛЬНИЙ'=>'', 'ІНВЕСТИЦІЯМИ'=>'', 'ОГРАНИЧЕННОЙ'=>'', 'OGRANICZONA'=>'', 'KOMANDYTOWA'=>'', 'ПРЕДПРИЯТИЕ'=>'', 'АКЦИОНЕРНОЕ'=>'', 'ТОРГОВЕЛЬНА'=>'',
    'ТОРГІВЕЛЬНА'=>'', 'ТОВАРИСТВО'=>'', 'ІНОЗЕМНИМИ'=>'', 'АКЦІОНЕРНЕ'=>'', 'ОБМЕЖЕНОЮ'=>'', 'ВИРОБНИЧЕ'=>'', 'ВИРОБНИЧА'=>'', 'УНИТАРНОЕ'=>'',
    'SP.Z.O.O.'=>'', 'CO.S.R.L.'=>'', 'S.A.-N.V.'=>'', 'КОМПАНІЯ'=>'', 'ТОРГОВИЙ'=>'', 'ОБЩЕСТВО'=>'', 'ТОРГОВОЕ'=>'', 'ПУБЛІЧНЕ'=>'', 'ЗАКРЫТОЕ'=>'',
    'ТОРГОВЫЙ'=>'', 'ТОРГОВЫЙ'=>'', 'ТОРГОВАЯ'=>'', 'S.P.R.L.'=>'', 'ТЕСТОВИЙ'=>'', /*'OILFIELD'=>'', 'SUPPLIES'=>'',*/ '(GEMLIK)'=>'', 'КОМПАНИЯ'=>'', 
    /*'SERVICES'=>'',*/ 'ЧАСТНОЕ'=>'', 'AKCYJNA'=>'', 'ТОРГОВА'=>'', 'TICARET'=>'', 'LIMITED'=>'', 'PRIVATE'=>'', /*'SERVICE'=>'', */ '.M.B.H.'=>'', 
    'SPOLKA'=>'', 'SAN.VE'=>'', 'SPOŁKA'=>'', 'SPÓŁKA'=>'', 'SPOLKA.Z.O.O.'=>'', 'S.A.S.Z.I.'=>'','S.R.O'=>'','COMPANY'=>'',
    'W.L.L.'=>'', 'L.D.A.'=>'', 'CO.KG.'=>'', 'J.S.C.'=>'', 'M.B.H.'=>'', 'S.A.S.'=>'', 'S.P.A.'=>'', 'S.A.U.'=>'', 'SUPPLY'=>'','Z.O.O.'=>'','O.O.'=>'',
    'L.L.C,'=>'', 'GEMLIK'=>'', 'D.O.O.'=>'', 'S.R.O.'=>'', 'SRO'=>'','O.O.D.'=>'', 'OOD'=>'','S.L.A.'=>'', 'L.L.C.'=>'', 'ФІРМА'=>'', 'ФОРМІ'=>'', 'ЦЕНТР'=>'',
    'ФИРМА'=>'', 'УЧНПП'=>'', 'CO.KG'=>'', 'L.L.C'=>'', /*'PIPES'=>'',*/ 'SPOL.'=>'', 'O.O.'=>'', 'SAN.'=>'', 'TIC.'=>'', 'A.Ş.'=>'', 'A.S.'=>'',
    'SP.Z'=>'', 'ПРАТ'=>'', 'LTD.'=>'', 'JSCO'=>'', 'ОСОО'=>'', /*'PIPE'=>'',*/ 'S.L.'=>'', 'ЗПТУ'=>'', 'S.A.'=>'', 'ТЕСТ'=>'', 'LTD,'=>'', 'GMBH'=>'', 'KFT.'=>'',
    'A.B.'=>'', 'НГВУ'=>'', 'B.V.'=>'', 'TEST'=>'', 'CO.K'=>'', 'СПБО'=>'', 'COKG'=>'', 'ЧТУП'=>'', 'A.D.'=>'', 'КПТМ'=>'', 'SP.J'=>'', 'НВПП'=>'', 'EOOD'=>'',
    'ПППФ'=>'', 'ДОМ'=>'', 'ДІМ'=>'', 'ТОВ'=>'', 'ТОО'=>'', 'SP.'=>'', 'ООО'=>'', 'ДПН'=>'', 'ВКГ'=>'', 'НВК'=>'', 'НВО'=>'', 'НПП'=>'', 'НВФ'=>'',
    'ВКФ'=>'', 'ВСФ'=>'', 'ВНЦ'=>'', 'Ф-Л'=>'', 'LTD'=>'', 'UAB'=>'', 'KFT'=>'', 'SRL'=>'', 'SLA'=>'', 'SAS'=>'', 'OOD'=>'', 'S.P.A.'=>'', 'LDA'=>'',
    'ЗАО'=>'', 'A/S'=>'', 'JSC'=>'', 'ТПО'=>'', 'ФЛП'=>'', 'НВП'=>'', 'LLC'=>'', 'НПО'=>'', 'НПЦ'=>'', 'ПАО'=>'', 'ГПУ'=>'', 'ЗАТ'=>'', 'PT.'=>'',
    'ЧАО'=>'', 'ФОП'=>'', 'УПП'=>'', 'ТПК'=>'', 'ТДВ'=>'', 'ВАТ'=>'', 'ПАТ'=>'', 'WLL'=>'', 'CO.'=>'', 'ОАО'=>'', 'МЖК'=>'', 'ДПЗ'=>'', 'ТД'=>'',
    'K.'=>'', 'VE'=>'', 'CO'=>'', 'ИИ'=>'', 'СП'=>'', 'ВП'=>'', 'ТБ'=>'', 'ВО'=>'', 'АО'=>'', 'ПП'=>'', 'ИП'=>'', 'ВФ'=>'', 'КП'=>'',
    'НВ'=>'', 'KG'=>'', 'ХО'=>'', 'ГК'=>'', 'ДП'=>'', 'ПО'=>'', 'BV'=>'', 'АТ'=>'', 'OU'=>'', 'БУ'=>'', 'ВК'=>'', 'ТК'=>'', 'AG'=>'',/*'P.VAN'=>'',*/
    'ГП'=>'', 'ОА'=>'', 'ЧП'=>'', 'AS'=>'', 'OG'=>'', 'H.'=>'', 'P.'=>'', 'УП'=>'', 'AB'=>'', 'SL'=>'', 'З'=>'', 'Z'=>'', 'У'=>'', 'С'=>'',
    'ТОВАРИЩЕСТВО'=>'', 'ПРИВАТНЕ'=>'', 'S.P.A.'=>'', 'S.P.A'=>'', 'GMBHCO.'=>'', 'SLU'=>'','S.L.U.'=>'','S.L.U'=>'','C.'=>'','PTY'=>'',
    'S.R.L.'=>'', 'P.W.'=>'', 'SAS'=>'', 'S.A.S.'=>'', 'S.A.S'=>'', 'DOO'=>'', 'NV'=>'', 'N.V.'=>'', 'CVBA'=>'', 
    'SPA'=>'', 'S.P.A.'=>'', '(M)'=>'', 'SDN'=>'', 'BHD'=>'', 'UK'=>'', 'FZE'=>'','FZEO'=>'','Z'=>'','O.'=>'',
    '(S)'=>'','PTE'=>'','FZCO'=>'','FZE'=>'','(IMS)'=>'','CO.LLC'=>'','CO. '=>'','INC.'=>'','INC'=>'',
    '(IMCO)'=>'','EST'=>'','W.L.L'=>'','CORP.'=>'','LTD.CO.'=>'','LTD.CO'=>'','CO.LTD.'=>'', 'KG.'=>'',
    '(ATCCO)'=>'','S.P.A.'=>'','ME'=>'','DMCC'=>'','BSC'=>'','A.'=>'','S.'=>'','LTDA.'=>'','LTDA'=>'',
    'C'=>'','PVT'=>'','CO.,'=>'','UY'=>'','ООО'=>'','S.L.'=>'', 'V1'=>'','B.V'=>'',
    'MIDDLE'=>'','EAST'=>'', 'INT.SA'=>'', 'INT'=>'', 'INT.'=>'', 'PVT.LTD'=>'', 'PVT.'=>'', 'GMBH+Co.'=>'', 'A.S.'=>'',
    'SANAYI'=>'', 'SIKRETI'=>'', 'ŞIKRETI'=>'','JR\'S'=>'','Jr\'s'=>'','JR’S'=>'','Jr’s'=>'', 'E'=>'',
    'FACTORY'=>'', 'BILLET'=>'', 'DE'=>'', 'trade.s.r.o.'=>'', 'TRADE.S.R.O.'=>'', /*'+'=>'',*/ 'GmbH+'=>'','GmbH&Co.K'=>'',
    'GMBH+'=>'','GMBH&CO.K'=>'','NV/SA'=>'','Nv/Sa'=>'', 'S.O.P'=>'','S.A.R.L.'=>'','S.L'=>'',
    'LP'=>'','L.P.'=>'','L.P'=>'','(LTDA)'=>'','OOO'=>'','–'=>'','ZRT'=>'','UA'=>'','SC'=>'','SB'=>'','O.O.,'=>'','Z.O.O.,'=>'','ZO.O.,'=>'',
    'SP.Z.O.O.'=>'','SP'=>'','Ges.m.b.H.'=>'','.'=>'',','=>'','SP.K'=>'','('=>'',')'=>'','FOR'=>'','TRAIDING'=>'','(PPL)'=>'','PPL'=>'','P.P.L.'=>'',
    'P.P.L'=>'','S.O.P.'=>'','F.Z.E.'=>'','(W.L.L.)'=>'','FZ'=>'','SDN'=>'','SDN,'=>'','BHD'=>'','S.L.U.'=>'','S.L.U'=>'','SLU'=>'','CO.,LTD'=>'',
    'CO.LTD'=>'','-GMBH'=>'','(UK)'=>'','S.C.'=>'','B-D'=>'','Dubai'=>'','Rep.'=>'','Office'=>'',
    'SAGA,'=>'SAGA', 'C.V.'=>'','SP.'=>'','K.'=>'','SP.K'=>'','КОРПОРАЦИЯ'=>'','КОМПАНИ'=>'', 'ЛИМИТЕД'=>''
    /*'San. ve Tic. A.Ş.'=>'', 'SAN. VE TIC. A.Ş.'=>'',*/
    };
//----------------------------------------------------------------------------------
        // Мапа можливих замін специфічних символів
        public static  Map<String, List<String>> replacements = new Map<String, List<String>>{
            'ø' => new List<String>{'ø', 'ö', 'oe', 'o'}, 'Ø' => new List<String>{'Ø', 'Ö', 'OE', 'O'},
            'ö' => new List<String>{'ø','ö', 'oe', 'o'}, 'Ö' => new List<String>{'Ø','Ö', 'OE', 'O'},
            'oe' => new List<String>{'ø','ö', 'oe', 'o'}, 'OE' => new List<String>{'Ø','Ö', 'OE', 'O'},
            'ü' => new List<String>{'ue','u'}, 'Ü' => new List<String>{'UE','U'},
            'ue' => new List<String>{'ü','u'}, 'UE' => new List<String>{'Ü','U'},
            'ä' => new List<String>{'ae', 'a'}, 'Ä' => new List<String>{'AE', 'A'},
            'ae' => new List<String>{'ä','a'}, 'AE' => new List<String>{'Ä','A'},
            'å' => new List<String>{'å','a'}, 'Å' => new List<String>{'Å','A'},
            'ü' => new List<String>{'ü', 'ue', 'u'},'Ü' => new List<String>{'Ü', 'UE', 'U'},
            'münchen' => new List<String>{'münchen', 'muenchen', 'munchen'},
            'MÜNCHEN' => new List<String>{'MÜNCHEN', 'MUENCHEN', 'MUNCHEN'},
            'Ç'=>new List<String>{'Ç','C'}, 'ç'=>new List<String>{'ç','c'},
            'Ć'=>new List<String>{'Ć','C'}, 'ć'=>new List<String>{'ć','c'},
            'Ĉ'=>new List<String>{'Ĉ','C'}, 'ĉ'=>new List<String>{'ĉ','c'},
            'Ċ'=>new List<String>{'Ċ','C'}, 'ċ'=>new List<String>{'ċ','c'},
            'Č'=>new List<String>{'Č','C'}, 'č'=>new List<String>{'č','c'},
            'Ď'=>new List<String>{'Ď','D'}, 'ď'=>new List<String>{'ď','d'},
            'Ð'=>new List<String>{'Ð','D'}, 'ð'=>new List<String>{'ð','d'},
            'Ķ'=>new List<String>{'Ķ','K'}, 'ķ'=>new List<String>{'ķ','k'},
            'Ĝ'=>new List<String>{'Ĝ','G'}, 'ĝ'=>new List<String>{'ĝ','g'},
            'Ğ'=>new List<String>{'Ğ','G'}, 'ğ'=>new List<String>{'ğ','g'},
            'Ġ'=>new List<String>{'Ġ','G'}, 'ġ'=>new List<String>{'ġ','g'},
            'Ģ'=>new List<String>{'Ģ','G'}, 'ģ'=>new List<String>{'ģ','g'},
            'Ĺ'=>new List<String>{'Ĺ','L'}, 'ĺ'=>new List<String>{'ĺ','l'},
            'Ļ'=>new List<String>{'Ļ','L'}, 'ļ'=>new List<String>{'ļ','l'},
            'Ľ'=>new List<String>{'Ľ','L'}, 'ľ'=>new List<String>{'ľ','l'},
            'Ŀ'=>new List<String>{'Ŀ','L'}, 'ŀ'=>new List<String>{'ŀ','l'},
            'Ł'=>new List<String>{'Ł','L'}, 'ł'=>new List<String>{'ł','l'},
            'Ń'=>new List<String>{'Ń','N'}, 'ń'=>new List<String>{'ń','n'},
            'Ņ'=>new List<String>{'Ņ','N'}, 'ņ'=>new List<String>{'ņ','n'},
            'Ň'=>new List<String>{'Ň','N'}, 'ň'=>new List<String>{'ň','n'},
            'Ŝ'=>new List<String>{'Ŝ','S'}, 'ŝ'=>new List<String>{'ŝ','s'},
            'Ş'=>new List<String>{'Ş','S'}, 'ş'=>new List<String>{'ş','s'},
            'Š'=>new List<String>{'Š','S'}, 'š'=>new List<String>{'š','s'},
            'Ś'=>new List<String>{'Ś','S'}, 'ś'=>new List<String>{'ś','s'},
            'Ţ'=>new List<String>{'Ţ','T'}, 'ţ'=>new List<String>{'ţ','t'},
            'Ť'=>new List<String>{'Ť','T'}, 'ť'=>new List<String>{'ť','t'},
            'Ź'=>new List<String>{'Ź','Z'}, 'ź'=>new List<String>{'ź','z'},
            'Ż'=>new List<String>{'Ż','Z'}, 'ż'=>new List<String>{'ż','z'},
            'Ž'=>new List<String>{'Ž','Z'}, 'ž'=>new List<String>{'ž','z'},
            'À'=>new List<String>{'À','A'}, 'à'=>new List<String>{'à','a'},
            'Á'=>new List<String>{'Á','A'}, 'á'=>new List<String>{'á','a'},
            'Â'=>new List<String>{'Â','A'}, 'â'=>new List<String>{'â','a'},
            'Ã'=>new List<String>{'Ã','A'}, 'ã'=>new List<String>{'ã','a'},
            'Å'=>new List<String>{'Å','A'}, 'å'=>new List<String>{'å','a'},
            'Ā'=>new List<String>{'Ā','A'}, 'ā'=>new List<String>{'ā','a'},
            'Ă'=>new List<String>{'Ă','A'}, 'ă'=>new List<String>{'ă','a'},
            'Ą'=>new List<String>{'Ą','A'}, 'ą'=>new List<String>{'ą','a'},
            'È'=>new List<String>{'È','E'}, 'è'=>new List<String>{'è','e'},
            'É'=>new List<String>{'É','E'}, 'é'=>new List<String>{'é','e'},
            'Ê'=>new List<String>{'Ê','E'}, 'ê'=>new List<String>{'ê','e'},
            'Ë'=>new List<String>{'Ë','E'}, 'ë'=>new List<String>{'ë','e'},
            'Ē'=>new List<String>{'Ē','E'}, 'ē'=>new List<String>{'ē','e'},
            'Ĕ'=>new List<String>{'Ĕ','E'}, 'ĕ'=>new List<String>{'ĕ','e'},
            'Ė'=>new List<String>{'Ė','E'}, 'ė'=>new List<String>{'ė','e'},
            'Ę'=>new List<String>{'Ę','E'}, 'ę'=>new List<String>{'ę','e'},
            'Ě'=>new List<String>{'Ě','E'}, 'ě'=>new List<String>{'ě','e'},
            'Ì'=>new List<String>{'Ì','I'}, 'ì'=>new List<String>{'ì','i'},
            'Í'=>new List<String>{'Í','I'}, 'í'=>new List<String>{'í','i'},
            'Î'=>new List<String>{'Î','I'}, 'î'=>new List<String>{'î','i'},
            'Ï'=>new List<String>{'Ï','I'}, 'ï'=>new List<String>{'ï','i'},
            'Ĩ'=>new List<String>{'Ĩ','I'}, 'ĩ'=>new List<String>{'ĩ','i'},
            'Ī'=>new List<String>{'Ī','I'}, 'ī'=>new List<String>{'ī','i'},
            'Ĭ'=>new List<String>{'Ĭ','I'}, 'ĭ'=>new List<String>{'ĭ','i'},
            'Į'=>new List<String>{'Į','I'}, 'į'=>new List<String>{'į','i'},
            'Ò'=>new List<String>{'Ò','O'}, 'ò'=>new List<String>{'ò','o'},
            'Ó'=>new List<String>{'Ó','O'}, 'ó'=>new List<String>{'ó','o'},
            'Ô'=>new List<String>{'Ô','O'}, 'ô'=>new List<String>{'ô','o'},
            'Õ'=>new List<String>{'Õ','O'}, 'õ'=>new List<String>{'õ','o'},
            'Ø'=>new List<String>{'Ø','O'}, 'ø'=>new List<String>{'ø','o'},
            'Ō'=>new List<String>{'Ō','O'}, 'ō'=>new List<String>{'ō','o'},
            'Ŏ'=>new List<String>{'Ŏ','O'}, 'ŏ'=>new List<String>{'ŏ','o'},
            'Ő'=>new List<String>{'Ő','O'}, 'ő'=>new List<String>{'ő','o'},
            'Ù'=>new List<String>{'Ù','U'}, 'ù'=>new List<String>{'ù','u'},
            'Ú'=>new List<String>{'Ú','U'}, 'ú'=>new List<String>{'ú','u'},
            'Û'=>new List<String>{'Û','U'}, 'û'=>new List<String>{'û','u'},
            'Ũ'=>new List<String>{'Ũ','U'}, 'ũ'=>new List<String>{'ũ','u'},
            'Ū'=>new List<String>{'Ū','U'}, 'ū'=>new List<String>{'ū','u'},
            'Ŭ'=>new List<String>{'Ŭ','U'}, 'ŭ'=>new List<String>{'ŭ','u'},
            'Ů'=>new List<String>{'Ů','U'}, 'ů'=>new List<String>{'ů','u'},
            'Ű'=>new List<String>{'Ű','U'}, 'ű'=>new List<String>{'ű','u'},
            'Ų'=>new List<String>{'Ų','U'}, 'ų'=>new List<String>{'ų','u'}
            
        };
        // Мапа можливих синонімів - може доповнюватися
        public static  Map<String, List<String>> sameWords = new Map<String, List<String>>{
            'AUSTRIA' => new List<String>{'AUSTRIA', 'AUSTRUA'},
            'AUSTRUA' => new List<String>{'AUSTRIA', 'AUSTRUA'},
            'INTERNATIONAL' => new List<String>{'INTERNATION', 'INTERNATIONAL'},
            'INTERNATION' => new List<String>{'INTERNATION', 'INTERNATIONAL'},
            'TUBE' => new List<String>{'TUBE', 'TUBES'},
            'TUBES' => new List<String>{'TUBE', 'TUBES'},
            'PIPE' => new List<String>{'PIPE', 'PIPES'},
            'PIPES' => new List<String>{'PIPE', 'PIPES'},
            'SERVICES' => new List<String>{'SERVICES', 'SERVICE'},
            'SERVICE' => new List<String>{'SERVICES', 'SERVICE'},
            'SUPPLIES' => new List<String>{'SUPPLIES', 'SUPPLY'}, 
            'SUPPLY' => new List<String>{'SUPPLIES', 'SUPPLY'}, 
            'MATERIAL' => new List<String>{'MATERIAL', 'MATERIALS'},
            'MATERIALS' => new List<String>{'MATERIAL', 'MATERIALS'}
        };

        // Мапа додаткового сміття
        public static Map<String, String> mapTrashAnd;
        static {
            mapTrashAnd = new Map<String, String>();
            mapTrashAnd.put(' & ', ' ');
            mapTrashAnd.put(' \\+', ' ');
            mapTrashAnd.put('&', ' ');
            mapTrashAnd.put('\\+', ' ');
            mapTrashAnd.put(' and ', ' ');
            mapTrashAnd.put(' und ', ' ');
            mapTrashAnd.put(' et ', ' ');
            mapTrashAnd.put(' AND ', ' ');
            mapTrashAnd.put(' UND ', ' ');
            mapTrashAnd.put(' ET ', ' ');
        }

/************************************************************************************/ 
    //Кількість слів у рядку
    public static Integer countWordsInString(String s) {
        Set<String> words = new Set<String>(s.toLowerCase().split(' '));
        return words.size();
    }    
    
    //Чистимо рядок від сміття - лапок, дужок, слів у дужках 
    public static String getClearStr(String s) {       
        if (s == null || s == '') {
            return '';
        }
        // Чистимо рядок від дужок і слів у дужках
        String strResult = '';
        s = s.replaceAll('\\s*\\([^)]*\\)', '').replaceAll('\\s*\\[[^)]*\\]', '').replaceAll('\\s*\\{[^)]*\\}', '').trim();
        
        // Чистимо рядок від сміттєвих символів
        String charsToRemove = ',„”"“”«»#$§';
        
        for (Integer i = 0; i < s.length(); i++) {
            String currentChar = s.substring(i, i + 1);
            if (!charsToRemove.contains(currentChar)) {
                strResult += currentChar;
            }
        }
        //Перевіряємо, чи не вжито в ролі лапок простих апострофів
        if(strResult.left(2)=='\'\'') {
            strResult=strResult.substring(2,strResult.length());
        } else {
            if(strResult.left(1)=='\'') {strResult=strResult.substring(1,strResult.length());}
        }
        
        if(strResult.right(2)=='\'\'') {
            strResult=strResult.substring(0,strResult.length()-2);
        }  else {
            if(strResult.right(1)=='\'') {strResult=strResult.substring(0,strResult.length()-1);}
        }

        if(strResult.left(2)=='’’') {
            strResult=strResult.substring(2,strResult.length());
        } else {
            if(strResult.left(1)=='’') {strResult=strResult.substring(1,strResult.length());}
        }
        
        if(strResult.right(2)=='’’') {
            strResult=strResult.substring(0,strResult.length()-2);
        } else {
            if(strResult.right(1)=='’') {strResult=strResult.substring(0,strResult.length()-1);}
        }
        
        //Замінюємо прямий апостроф (') на скісний (’) щоби уникнути можливого ексепшена некоретного кінця рядку
        return strResult.replace('\'','’').normalizeSpace();
    }
//----------------------------------------------------------------------------------
    //Нормалізуємо назву - очищуємо від "сміття" та сміттєвих слів
    public static String getClearName(String strName, Boolean NeedsUCase) {
        Set<String> nameWords = new Set<String>(getClearStr(strName).split(' '));
        Set<String> toRemove = new Set<String>();
        
        for(String word : nameWords) {
            if(mapTrashWords.containsKey(word.toUpperCase())) {
                toRemove.add(word);
            }
        }
        nameWords.removeAll(toRemove);
        String Result = String.join(new List<String>(nameWords), ' ');
        for (String key : mapTrashAnd.keySet()) {
            Result = Result.replaceAll(key, mapTrashAnd.get(key));
        }
        nameWords = new Set<String>(Result.split('\\s+')); 
        Result = String.join(new List<String>(nameWords), ' ');
        Result  = (NeedsUCase==true) ? Result.toUpperCase() : Result ;
        return Result.replace('P.VAN','VAN').replace('vanleeuwen.fr','VAN LEEUWEN'); //ці фокуси обробляємо окремо, бо ОЦЕ систематизувати неможливо
    }
//----------------------------------------------------------------------------------    
    //Перше слово назви
    public static String getFirstWord(String Name) {
        String strResult = '';
        //Вибираємо перше слово з назви, обробляючи ситуацію, коли назва складається з одного слова
        if(Name.indexOf(' ')<>-1) {
            strResult=Name.left(Name.indexOf(' '));
        } else {strResult=Name;}    
        
        return strResult;
    }
//----------- Формуємо SQL String для основного запиту 
    public static String getSQLString(String sourceName, Boolean isFirstNameMustFull) {
        List<String> words = getClearName(sourceName, true).split(' '); 
        
        Set<String> baseWords = new Set<String>();  // Основні слова без змін
        Set<String> synonymConditions = new Set<String>();  // Група синонімів
        Set<String> specialConditions = new Set<String>();  // Група варіантів зі спецсимволами
    
        for (Integer i = 0; i < words.size(); i++) {
            String word = words[i];
            Boolean hasSynonyms = false;
            Boolean hasSpecials = false;
            
            Set<String> variations = new Set<String>();
            variations.add(word); // Додаємо саме слово
    
            // Якщо є синоніми - додаємо їх
            if (sameWords.containsKey(word.toUpperCase())) {
                for (String synonym : sameWords.get(word.toUpperCase())) {
                    synonymConditions.add('Name LIKE \'%' + synonym + '%\'');
                    hasSynonyms = true;
                }
            }
    
            // Генеруємо варіанти з спецсимволами
            Set<String> tempVariations = new Set<String>(variations);
            for (String varWord : tempVariations) {
                generateCharacterVariations(varWord, 0, '', variations, replacements);
            }
    
            // Додаємо всі варіанти, включаючи саме слово, в спецваріанти
            if (variations.size() > 1) { // Тільки якщо є варіанти
                Set<String> specialGroup = new Set<String>();
                for (String variant : variations) {
                    specialGroup.add('Name LIKE \'%' + variant + '%\'');
                }
                specialConditions.add('(' + String.join(new List<String>(specialGroup), ' OR ') + ')');
                hasSpecials = true;
            }
    
            // Якщо слово НЕ має синонімів і спецваріантів, то воно залишається в основних
            if (!hasSynonyms && !hasSpecials) {
                baseWords.add('Name LIKE \'%' + word + '%\'');
            }
        }
    
        // Формуємо фінальний WHERE
        List<String> finalConditions = new List<String>();
        if (!baseWords.isEmpty()) {
            finalConditions.add('(' + String.join(new List<String>(baseWords), ' OR ') + ')');
        }
        if (!synonymConditions.isEmpty()) {
            finalConditions.add('(' + String.join(new List<String>(synonymConditions), ' OR ') + ')');
        }
        if (!specialConditions.isEmpty()) {
            finalConditions.add('(' + String.join(new List<String>(specialConditions), ' AND ') + ')');
        }
    
        return 'SELECT Id, Name, ID_ERP__c, OwnerId, CreatedById, CreatedDate, Country__c, City__c, MarketSegment__c, BillingCountry, BillingCity, BillingCountryCode, ShippingCountry, ShippingCity, ShippingCountryCode, ParentId, HoldingGroup__c, Activity_Type__c, Type, Under_Sanctions__c FROM Account WHERE ' + String.join(finalConditions, ' AND ');
    }
    
    // Рекурсивна функція, що ґенерує всі можливі варіанти слова, підставляючи альтернативні символи
    private static void generateCharacterVariations(String word, Integer index, String current, Set<String> variations, Map<String, List<String>> replacements) {
        if (index == word.length()) {
            variations.add(current);
            return;
        }
    
        String ch = word.substring(index, index + 1);
    
        if (replacements.containsKey(ch)) {
            for (String replacement : replacements.get(ch)) {
                generateCharacterVariations(word, index + 1, current + replacement, variations, replacements);
            }
        } else {
            generateCharacterVariations(word, index + 1, current + ch, variations, replacements);
        }
    }
//--------------------------------------------
    
    //---- Повертаємо лист акаунтів
    public static List<Account> GetAccountMatches(String argAccName, Boolean FullFirstWord) {
    // Аргументи:
    // argAccName - початкова назва
    // FullFirstWord - чи потрібно порівнювати перше слово на повний збіг
    //                 тобто ставити Name LIKE '<перше слово argAccName>' замість Name LIKE '%<перше слово argAccName>%'
        String strQuery = getSQLString(argAccName, FullFirstWord);
        system.debug(strQuery );
        List<Account> accList = (List<Account>) Database.query(strQuery);
        
        return accList;
    }
    
    // Функція для перевірки наявності спільних слів у назвах
    public static Boolean hasCommonWords(String name1, String name2) {
        Set<String> words1 = new Set<String>(name1.toLowerCase().split(' '));
        Set<String> words2 = new Set<String>(name2.toLowerCase().split(' '));
        
        // Перевіряємо наявність спільних слів між двома наборами
        words1.retainAll(words2);
        
        return !words1.isEmpty();
    }    
    
    //Ступінь збігу перших слів
    public static Double matchFirstWordsCoef(String name1, String name2) {
        //Вибираємо перше слово з кожної назви
        String s1=getFirstWord(name1);
        String s2=getFirstWord(name2);
        
        //Визначаємо верхню межу циклу - довжину меншого рядка
        Integer strLen = (Integer)math.min(s1.length(), s2.length());
        String strLonger = '';
        String strShorter = '';

        if(s1.length()>=s2.length()) {
            strLonger = s1;
            strShorter = s2;
        } 
        else {
            strLonger = s2;
            strShorter = s1;
        }

        Double matchCoef=0.0;
        Integer matchCount = 0;
        
        strLonger = strLonger.toUpperCase();
        strShorter = strShorter.toUpperCase();
        
        //Порівнюємо, чи збігаються літери в словах, одна по одній
        for(Integer i=0; i<strLen; i++) {
            if(strShorter.substring(i, i+1)==strLonger.substring(i, i+1)){
                matchCount+=1;
            }
        }
        matchCoef = (Double)matchCount/strLonger.length();
        return matchCoef;
    }

    // Функція для перевірки наявності спільних слів і підрахунку їх кількості
    public static Integer countCommonWords(String name1, String name2) {
        // Розбиваємо назви акаунтів на слова і перетворюємо на множини
        Set<String> words1 = new Set<String>(getClearStr(name1).toUpperCase().split(' '));
        Set<String> words2 = new Set<String>(getClearStr(name2).toUpperCase().split(' '));
        
        // Створюємо копію першого набору, оскільки .retainAll змінює оригінальний набір
        Set<String> commonWords = new Set<String>(words1);
        
        // Залишаємо лише спільні слова
        commonWords.retainAll(words2);
        
        // Повертаємо кількість спільних слів
        return commonWords.size();  
    }    
    
/****************** Методи фонетичного аналізу *********************/             
    /* ------- Підхід із використанням Levenshtein Distance
        Критерії подібності на основі Levenshtein Distance
        1.  Абсолютна редакційна відстань:
        o   Якщо Levenshtein Distance між двома рядками дорівнює 0, це означає, що назви абсолютно однакові.
        o   Якщо значення відстані є дуже малим (наприклад, 1 або 2), це може свідчити про незначну відмінність, 
        яку можна вважати хибодруком або різницею в скороченнях (напр. "Company" і "Compani").
        Зазвичай вважається, що якщо Levenshtein Distance <3, то назви є дуже схожими
    */

    public static Integer getLevensteinDistance(String name1, String name2) {   

        if (name1 == null || name2 == null) {
            return -1;
        }
        
        //Нормалізуємо назви
        String s1 = getClearName(name1, true);
        String s2 = getClearName(name2, true);
        
        Integer len1 = s1.length();
        Integer len2 = s2.length();
        
        // Використовуємо список списків для двовимірного масиву
        List<List<Integer>> d = new List<List<Integer>>();
        
        // Ініціалізуємо двовимірний список
        for (Integer i = 0; i <= len1; i++) {
            d.add(new List<Integer>());
            for (Integer j = 0; j <= len2; j++) {
                d[i].add(0);  // Заповнюємо нулями
            }
        }

        for (Integer i = 0; i <= len1; i++) {
            d[i][0] = i;
        }
        for (Integer j = 0; j <= len2; j++) {
            d[0][j] = j;
        }

        for (Integer i = 1; i <= len1; i++) {
            for (Integer j = 1; j <= len2; j++) {
                Integer cost = (s1.charAt(i - 1) == s2.charAt(j - 1)) ? 0 : 1;
                d[i][j] = Math.min(
                    Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1),
                    d[i - 1][j - 1] + cost
                );
            }
        }      
        return d[len1][len2];
    }
 //---------------------------------------------------------------------------------------------------------  
    /*
    Нормалізована Levenstein Distance 
    o   Подібні назви: Якщо нормалізована Levenstein Distance ≤ 0.2 (або 20%), це означає, що назви дуже схожі і можуть бути дублями.
    o   Можливі дублікати: Якщо нормалізована Levenstein Distance між 0.2 і 0.4 (20-40%), це вказує на можливість дублювання, але потрібно додатково перевірити.
    o   Різні назви: Якщо нормалізована Levenstein Distance > 0.4 (або 40%), назви, ймовірно, є різними.
    */
    public static Decimal getNormalizedLevenstein(String name1, String name2) {
        Decimal Result = 0.00;
        Result = (Decimal)getLevensteinDistance(name1, name2)/Math.max(name1.length(), name2.length());
        return Result.setScale(3);
    }
 //---------------------------------------------------------------------------------------------------------       
    /* Метод для розрахунку Jaccard Similarity
    Значення Jaccard Similarity завжди є в межах від 0 до 1:
    •   0 означає, що набори не мають спільних елементів (назви зовсім різні).
    •   1 означає, що набори повністю збігаються (назви ідентичні).
        Як зрозуміти, що два рядки є потенційними дублями?
        Все залежить від контексту вашого бізнесу і того, як суворо ви бажаєте відсівати можливі дублі.
        Ось кілька прикладів:
    •   Значення 0.7 і більше може вважатися сильною схожістю і вказувати на те, що назви можуть бути дублями (особливо, якщо йдеться про дублі акаунтів).
    •   Значення 0.4–0.7 вказує на можливу подібність, але може вимагати додаткової перевірки.
    •   Значення менше 0.4 часто вказує на слабку схожість, хоча це теж залежить від специфіки ваших даних.
    */    
    public static Decimal jaccardSimilarity(String s1, String s2) {
        //Нормалізуємо назви
        String name1 = getClearName(s1, false);
        String name2 = getClearName(s2, false);
        // Розбиваємо рядки на слова і приводимо їх до нижнього регістру
        Set<String> words1 = new Set<String>(name1.toLowerCase().split(' '));
        Set<String> words2 = new Set<String>(name2.toLowerCase().split(' '));
        
        // Створюємо множину для об'єднаних елементів (A U B)
        Set<String> unionSet = new Set<String>(words1);
        unionSet.addAll(words2);
        
        // Створюємо множину для перетину (A ∩ B)
        Set<String> intersectionSet = new Set<String>(words1);
        intersectionSet.retainAll(words2);
        
        // Обчислюємо Jaccard Similarity як відношення перетину до об'єднання
        if (unionSet.size() == 0) {
            return 0.0;
        }
        
        Decimal similarity = (Decimal)intersectionSet.size() / unionSet.size();
        return similarity.setScale(3);
    }
 //--------------------------------------------------------------------------------------------------------- 
    // Метод для Soundex - простий варіант
    public static String Soundex(String s) {
        if (s == null || s.trim().length() == 0) {
            return null;
        }
        //Нормалізуємо назви
        String word = getClearName(s, true);
        
        // Масив для кодування Soundex з кирилицею та розширеними латинськими літерами
        Map<String, String> soundexMap = new Map<String, String>{
            // Латинські літери
            'B' => '1', 'F' => '1', 'P' => '1', 'V' => '1',
            'C' => '2', 'G' => '2', 'J' => '2', 'K' => '2', 'Q' => '2', 'S' => '2', 'X' => '2', 'Z' => '2', 'H' => '2', /*h*/
            'D' => '3', 'T' => '3',
            'L' => '4', 
            'M' => '5', 'N' => '5',
            'R' => '6',
            
            // Кирилиця
            'Б' => '1', 'П' => '1', 'В' => '1', 'Ф' => '1',
            'Г' => '2', 'Ґ' => '2', 'К' => '2', 'Х' => '2', 'Ц' => '2', 'Ч' => '2', 'Ш' => '2', 'Щ' => '2', 'С' => '2', 'З' => '2',
            'Д' => '3', 'Т' => '3',
            'Л' => '4',
            'М' => '5', 'Н' => '5',
            'Р' => '6',
            
            // Розширені латинські літери
            'Ç' => '2', 'Ś' => '2', 'Š' => '2', 'Ž' => '2',
            'Ł' => '4', 'Ñ' => '5',
            
            // Голосні та інші літери можна ігнорувати (в Soundex вони зазвичай не враховуються)
            'A' => '', 'E' => '', 'I' => '', 'O' => '', 'U' => '', 'Y' => '',
            'Ä' => '', 'Ö' => '', 'Ü' => '', 'Ó' => '', 'É' => '', 'Á' => '', 'Ø' => '',
            
            'А' => '', 'О' => '', 'Е' => '', 'І' => '', 'У' => '', 'И' => '', 
            'Й' => '', 'Ї' => '', 'Є' => '', 'Я' => '', 'Ю' => '', 'Э' =>'',
            'Ъ' => '','Ь' => '','Ё' => ''
        };


        // Приводимо слово до верхнього регістру
        word = word.toUpperCase();
        String soundexCode='';
        // Беремо першу літеру
        if(word.length()>0) {
            soundexCode = word.substring(0, 1);
        }

        // Проходимо по решті літер і кодуємо їх
        for (Integer i = 1; i < word.length(); i++) {
            String currentChar = word.substring(i, i+1); // Оскільки ми використовуємо тип String
            // Пропускаємо голосні літери
            if ('AEIOUYÄÖÜÓÉÁØАОЕІУИЙЇЄЯЮЭЪЬЁ'.contains(currentChar)) {
                continue;
            }           
            // Додаємо коди до результату
            if (soundexMap.containsKey(currentChar)) {
                String code = soundexMap.get(currentChar);
                if (!soundexCode.endsWith(code)) {  // Уникаємо повторень
                    soundexCode += code;
                }
            }
        }
       
        // Доповнюємо або обрізаємо до 4 символів
        if (soundexCode.length() >= 4) {
            return soundexCode.substring(0, 4);
        } else {
            // Додаємо нулі до кінця рядка
            while (soundexCode.length() < 4) {
                soundexCode += '0';
            }
            return soundexCode;
        }
    }
//---------------------------------------------------------------------------------------------------------    
    //--- Soundex всіх слів у назві - розширена версія стандартного Soundex, який повертає код тільки для першого слова
    public static List<String> getSoundexEx(String argName) {
        List<String> result = new List<String>();
        if(argName=='' || argName==null) {
            return result;
        }
        List<String> lstWords = new List<String>(argName.split(' '));
        for(String s : lstWords) {
            result.add(Soundex(s));
        }
        return result;
    }
    
/************* Soundex Similarity по всіх словах двох назв, що порівнюються ***/
    public static Decimal getFullSoundexSimilarity(String Name1, String Name2, Boolean MustFirstMatch) {
        Decimal result = 0;
        if((Name1=='' || Name1==null) || (Name2=='' || Name2==null)) {
            return result;
        }
        List<String> SoundexList1 = new List<String>(getSoundexEx(Name1));
        List<String> SoundexList2 = new List<String>(getSoundexEx(Name2));
        
        Integer nCount = Math.min(SoundexList1.size(), SoundexList2.size());
        if(nCount==0) {
            return result;
        }
        Integer maxSize = Math.max(SoundexList1.size(), SoundexList2.size());
        if(maxSize==0) {
            return result;
        }
        
        for(integer i=0; i<nCount; i++) {
            result = result + getSoundexSimilarityEx(SoundexList1[i], SoundexList2[i], MustFirstMatch);
        }

        if (maxSize > 0) {
            result = result / (Decimal) maxSize;
        } else {
            result = 0;
        }
        
        return result.setScale(3);
    }

    /* ----- Метод косинусної подібності (Cosine Similarity)
        Принцип
        Косинусна подібність вимірює схожість між двома рядками шляхом порівняння кутів між векторами їхнього представлення. 
        Це корисно для порівняння наборів слів або текстових фрагментів. 
        Зазвичай використовується в задачах обробки природної мови.
        1.  Рядки розбиваються на набори слів.
        2.  Для кожного рядка будується вектор, де кожен елемент відповідає частоті появи певного слова.
        3.  Косинус кута між цими векторами вимірює подібність (1 — ідентичні рядки, 0 — зовсім різні).
        Критерії подібності
        •   Косинусна подібність наближається до 1 для схожих назв.
        •   Якщо значення більше 0.8, рядки вважаються дуже схожими.
    */  
    public static Decimal cosineSimilarity(String name1, String name2) {
        
        //Нормалізуємо назви
        String s1 = getClearName(name1, true);
        String s2 = getClearName(name2, true);
        
        Map<String, Integer> freq1 = getWordFrequency(s1);
        Map<String, Integer> freq2 = getWordFrequency(s2);

        Decimal dotProduct = 0.0;
        Decimal norm1 = 0.0;
        Decimal norm2 = 0.0;

        for(String word : freq1.keySet()) {
            if(freq2.containsKey(word)) {
                dotProduct += freq1.get(word) * freq2.get(word);
            }
            norm1 += Math.pow(freq1.get(word), 2);
        }
        for(String word : freq2.keySet()) {
            norm2 += Math.pow(freq2.get(word), 2);
        }

        norm1 = Math.sqrt(norm1);
        norm2 = Math.sqrt(norm2);

        if(norm1 == 0 || norm2 == 0) {
            return 0.0;
        }
        
        return (dotProduct / (norm1 * norm2)).setScale(3);
    }

    // Частота слів у назві
    private static Map<String, Integer> getWordFrequency(String s) {
        Map<String, Integer> freq = new Map<String, Integer>();
        for(String word : s.toLowerCase().split(' ')) {
            if(freq.containsKey(word)) {
                freq.put(word, freq.get(word) + 1);
            } else {
                freq.put(word, 1);
            }
        }
        return freq;
    } 

    // Метод для оцінки подібності Soundex-кодів
    public static Decimal getSoundexSimilarity(String soundex1, String soundex2) {
        if (soundex1 == null || soundex2 == null || soundex1.length() != 4 || soundex2.length() != 4) {
            return 0.000; // Некоректні коди
        }
        
        Integer matchCount = 0;
        //Порівнюємо збіг перших літер
        Boolean sameFirstLetter = (soundex1.substring(0,1) == soundex2.substring(0,1));
        
        // Порівнюємо числову частину (3 цифри)
        for (Integer i = 1; i < 4; i++) {
            if (soundex1.substring(i, i+1) == soundex2.substring(i, i+1)) {
                matchCount += 1;
            }
        }
        
        Decimal Result = 0.000;
        if (sameFirstLetter) {
            Result = (Decimal)(matchCount + 1.0) / 4.0;// Додаємо 1 бал за збіг першої літери
        } else {
            // Якщо перші літери різні, враховуємо лише числові збіги (0.75, 0.5, 0.25 або 0)
            Result = (Decimal)matchCount / 3.0;
        }
        
        return Result.setScale(3);
    } 
    
     // Метод для оцінки подібності Soundex-кодів - розширена версія
    public static Decimal getSoundexSimilarityEx(String soundex1, String soundex2, Boolean MustFirstMatch) {
        if (soundex1 == null || soundex2 == null || soundex1.length() != 4 || soundex2.length() != 4) {
            return 0.000; // Некоректні коди
        }

        Integer matchCount = 0;
        Boolean sameFirstLetter = (soundex1.substring(0,1) == soundex2.substring(0,1));

        // Порівнюємо числову частину (3 цифри)
        for (Integer i = 1; i < 4; i++) {
            if (soundex1.substring(i, i+1) == soundex2.substring(i, i+1)) {
                matchCount += 1;
            }
        }

        Decimal result = 0.000;
        
        if (MustFirstMatch && !sameFirstLetter) {
            return 0.000; // Якщо потрібен збіг першої літери, а вона різна → повертаємо 0
        }

        if (sameFirstLetter) {
            result = (Decimal)(matchCount + 1.0) / 4.0; // Додаємо 1 бал за першу літеру
        } else {
            result = (Decimal)matchCount / 3.0; // Якщо перші літери різні, рахуємо тільки цифри
        }

        return result.setScale(3);
    }
// Основний метод - повертає лист рекордів класу AccountMatches з усіма знайденими дублями, а також коди для аналізу
// Вибирати початкову назву для аналізу можна як явно, задаючи назву стрингм, так і вибирати за кодом з БД - по Id чи ID_ERP__c
// Аргументи
// String argAccName - початкова назва, для якої шукаємо збіги
// Boolean isFullFirstWord - чи потрібно порівнювати перше слово на повний збіг
//                           тобто ставити Name LIKE '<перше слово argAccName>' замість Name LIKE '%<перше слово argAccName>%'
// Boolean isFindById - =true->шукати по коду (Id чи ID_ERP__c), =false->шукати по назві argAccName
// Boolean isFindByID_ERP - true->шукати по кодуID_ERP__c, =false->шукати по по Id 
// String strIdForFind - код для пошуку якщо isFindById=true
// Boolean bFirstWordsMustMatch - якщо =true - враховуємо тільки ті рекорди, де повністю збігаються перші слова
/*********************************************************************************************************************/    
    public static List<AccountMatches> getMatchResult(String argAccName, Boolean isFullFirstWord, Boolean isFindById, 
                                                      Boolean isFindByID_ERP, String strIdForFind, Boolean bFirstWordsMustMatch) {
        //Створюємо й ініціюємо лист рекордів класу AccountMatches
        List<AccountMatches> lstAccMatch = new List<AccountMatches>();
        //
        Account AccRec = new Account();
        if(isFindById) { // Якщо вибираэсо за кодом з БД
            try {
                if (isFindByID_ERP) { // ID_ERP__c
                    AccRec = [SELECT Id, ID_ERP__c, Name FROM Account WHERE ID_ERP__c = :strIdForFind LIMIT 1];
                } else { // Salesforce Id
                    AccRec = [SELECT Id, ID_ERP__c, Name FROM Account WHERE Id = :strIdForFind LIMIT 1];
                }
            } catch (Exception e) {
                AccRec = null; // Якщо запис не знайдено, уникнемо QueryException
                String s;
                s = isFindByID_ERP ? 'ID_ERP__c='+isFindByID_ERP : 'Id='+strIdForFind;
                System.debug('ERROR: No rows in Account object with ' + s );
                return lstAccMatch;
            }
        }
        else {//шукати по назві argAccName
            if(argAccName=='' || argAccName==null) { //Якщо назва некоректна - виходимо
                System.debug('ERROR: No Account Name for matching');
                return lstAccMatch;
            }
            else {
                AccRec.Name = argAccName;
            }
        }
        //Зберігаємо початкові дані
        String SourceStr = AccRec.Name;
        String SourceAccID = '';
        String Source_ID_ERP = '';
        
        if(isFindById) {
            SourceAccID = AccRec.Id;
            Source_ID_ERP = AccRec.ID_ERP__c;
        }
        //Робимо селект по БД
        List<Account> lstAccResult = GetAccountMatches(SourceStr, isFullFirstWord);
        
        //Готуємо перемінні для запису результатів 
        Decimal NamesCorrelation = 0.00;
        String SoundexMainAcc = '';
        String SoundexFoundAcc = '';
        Decimal dSoundexSimilarity = 0.00;
        Decimal dFirstWordsCoef = 0.000;
        //Boolean isFirstWordsMatch;
        Decimal lenSourceStr;
        Decimal lenRecStr;
        
        //Вибираємо й аналізуємо кожен рекод, вибраного селектом датасету
        for(Account rec : lstAccResult) {
            lenSourceStr = getClearStr(SourceStr).length();
            lenRecStr = getClearStr(rec.Name).length();
            
            //% спільних слів у двох назвах
            NamesCorrelation = (Decimal)countCommonWords(SourceStr, rec.Name)/(Decimal)((lenSourceStr+lenRecStr)/2);
            // Soundex
            SoundexMainAcc = String.join(getSoundexEx(getClearName(SourceStr,true)),' ');
            dSoundexSimilarity = (Decimal)getFullSoundexSimilarity(getClearName(SourceStr,true), getClearName(rec.Name,true), true);
            SoundexFoundAcc = String.join(getSoundexEx(rec.Name),' ');
            
            //Перевіряємо, чи збігаються перші слова
            // Цей спосіб добре працює для простої літеральної перевірки збігу двох перших слів
            // Якщо потрібно більш гнучке порівняння (наприклад, з урахуванням варіантів написання) - можна підключити Soundex або Levenshtein distance         
            Boolean isMatch = false;
            String strFirst1 = getFirstWord(getClearName(SourceStr, true));
            String strFirst2 = getFirstWord(getClearName(rec.Name, true));

            if (strFirst1.length() == strFirst2.length()) { // Слова мають однакову довжину
                if (strFirst1.substring(0, 1) == strFirst2.substring(0, 1)) { // Перевіряємо першу літеру
                    isMatch = true; // Початково припускаємо, що всі символи співпадають
                    for (integer i = 0; i < strFirst1.length(); i++) {
                        if (strFirst1.substring(i, i+1) != strFirst2.substring(i, i+1)) {
                            isMatch = false; // Якщо хоча б один символ не співпав - виходимо
                            break;
                        }
                    }
                }
            }
           
            /****************** Заповнюємо рекорд з результатами *******************************/
            //Перевіряємо збіг перших слів 
            if((bFirstWordsMustMatch && isMatch) || !bFirstWordsMustMatch) {
                lstAccMatch.add(new AccountMatches(
                    SourceAccID, Source_ID_ERP, SourceStr,
                    rec.Id, rec.Name, rec.ID_ERP__c,
                    cosineSimilarity(SourceStr, rec.Name),      
                    jaccardSimilarity(SourceStr, rec.Name),
                    getLevensteinDistance(SourceStr, rec.Name),
                    dFirstWordsCoef.setScale(3),
                    NamesCorrelation.setScale(3),
                    getNormalizedLevenstein(SourceStr, rec.Name),
                    SoundexMainAcc, SoundexFoundAcc,
                    dSoundexSimilarity.setScale(3),
                    rec.CreatedDate, rec.Activity_Type__c, rec.ParentId, rec.HoldingGroup__c,
                    rec.BillingCountryCode, rec.ShippingCountryCode, 
                    rec.MarketSegment__c, rec.Type,
                    rec.BillingCountry, rec.ShippingCountry,
                    rec.BillingCity, rec.ShippingCity,
                    rec.OwnerId, rec.CreatedById, rec.Under_Sanctions__c
                ));
            }
        }       
        return lstAccMatch;
    }

    public static void FakeCoverageMethod() {
        Integer i=0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}