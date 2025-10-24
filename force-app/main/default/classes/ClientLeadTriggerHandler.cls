public class ClientLeadTriggerHandler {

		private class Pair {
			public List<ClientLeadTriggerHandler.Match> acc;
			public List<ClientLeadTriggerHandler.Match> lead;
			public Pair(List<ClientLeadTriggerHandler.Match> a, List<ClientLeadTriggerHandler.Match> l){
				this.acc  = (a == null) ? new List<ClientLeadTriggerHandler.Match>() : a;
				this.lead = (l == null) ? new List<ClientLeadTriggerHandler.Match>() : l;
			}
		}

		private static Map<String, List<Pair>> qByKey = new Map<String, List<Pair>>();

		private static void push(String key, List<ClientLeadTriggerHandler.Match> acc, List<ClientLeadTriggerHandler.Match> lead){
			if(!qByKey.containsKey(key)) qByKey.put(key, new List<Pair>());
			qByKey.get(key).add(new Pair(acc, lead));
		}

		private static Pair pop(String key){
			if(!qByKey.containsKey(key)) return new Pair(null, null);
			List<Pair> q = qByKey.get(key);
			if(q.isEmpty()) return new Pair(null, null);
			return q.remove(0);
		}

		private static String makeKey(ClientLead__c r){
			return String.valueOf(r.Name)
				 + '|' + String.valueOf(r.NormalizedName__c)
				 + '|' + String.valueOf(r.PhoneticCode__c)
				 + '|' + String.valueOf(r.NYSIIS__c)
				 + '|' + String.valueOf(r.MetaphonePrimary__c);
		}


    // Простий внутрішній DTO для матчів — зручно підміняти в тестах
    public class Match {
        public Id matchedId;
        public Decimal matchIndex;
        public String matchedName;
        public Match(Id matchedId, Decimal matchIndex, String matchedName){
            this.matchedId = matchedId;
            this.matchIndex = matchIndex;
            this.matchedName = matchedName;
        }
    }

    // Інтерфейс пошуку дублів
    public interface IDupFinder {
        List<Match> findAcc(String name, Decimal threshold);
        List<Match> findLead(String name, Decimal threshold);
    }

    // Реалізація за замовчуванням (адаптує твої утиліти до нашого Match)
    private class DefaultDupFinder implements IDupFinder {
        public List<Match> findAcc(String name, Decimal threshold){
            List<Match> out = new List<Match>();
            List<StringUtilsEx.MatchResult> src = NameSimilarityUtil.fastDuplicateCheck(name, threshold);
            for(StringUtilsEx.MatchResult mr : src){
                out.add(new Match(mr.account1Id, mr.matchIndex, mr.SourceName));
            }
            return out;
        }
        public List<Match> findLead(String name, Decimal threshold){
            List<Match> out = new List<Match>();
            List<StringUtilsEx.MatchResult> src = LeadUtils.findDuplicates(name, threshold);
            for(StringUtilsEx.MatchResult mr : src){
                out.add(new Match(mr.account1Id, mr.matchIndex, mr.SourceName));
            }
            return out;
        }
    }

    private static IDupFinder dupFinder = new DefaultDupFinder();

    @TestVisible
    static void setDupFinder(IDupFinder f){
        dupFinder = (f == null) ? new DefaultDupFinder() : f;
    }

    public static void handleBeforeInsert(List<ClientLead__c> newLeads) {
        Decimal threshold = 0.8;

        // 1 раз отримуємо поточного юзера
        User currentUser = [
            SELECT Id, Profile.Name, BusinesDivision__c, SalesDivision__c, Name
            FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1
        ];

        for (ClientLead__c newlead : newLeads) {
            // 1) Нормалізація/фонетика
            Map<String, String> normMap = StringNormalize.getNorNameAndPhoneticCodes(newlead.Name);
            if (normMap == null) normMap = new Map<String, String>();
            for(String key : normMap.keySet()) { 
                if(key=='NormalizedName__c') { //newlead.NormalizedName__c  = normMap.get(key);
                    if (!normMap.containsKey('NormalizedName__c')) {
                        newlead.NormalizedName__c = LeadUtils.getLeadNormName(newlead.Name);
                    }  else {
                        newlead.NormalizedName__c = normMap.get(key);
                    }                  
                }       
                if(key=='PhoneticCode__c')         newlead.PhoneticCode__c         = normMap.get(key);
                if(key=='NYSIIS__c')               newlead.NYSIIS__c               = normMap.get(key);
                if(key=='NYSIISFirstCode__c')      newlead.NYSIISFirstCode__c      = normMap.get(key);
                if(key=='SoundexAllWords__c')      newlead.SoundexAllWords__c      = normMap.get(key);
                if(key=='SoundexFirstWord__c')     newlead.SoundexFirstWord__c     = normMap.get(key);
                if(key=='SoundexFirst3Letters__c') newlead.SoundexFirst3Letters__c = normMap.get(key);
                if(key=='MetaphonePrimary__c')     newlead.MetaphonePrimary__c     = normMap.get(key);
                if(key=='MetaphoneAlternate__c')   newlead.MetaphoneAlternate__c   = normMap.get(key);
            }

            if (String.isBlank(newlead.Name)) continue;

            // 2) Пошук дублів (через інʼєкцію)
            List<Match> matchResultsAcc  = dupFinder.findAcc(newlead.Name, threshold);
            List<Match> matchResultsLead = dupFinder.findLead(newlead.Name, threshold);

            // 3) Rich Text для користувача
            List<String> htmlWarnings = new List<String>();
            if (!matchResultsAcc.isEmpty()) {
                htmlWarnings.add('<strong>⚠️ Potential duplicates in Accounts was found:</strong><br/>');
                for (Match m : matchResultsAcc) {
                    if (m.matchIndex >= threshold) {
                        String accName = m.matchedName;
                        Id accIdForLink = m.matchedId;

                        if (String.isBlank(accName)) {
                            Account accSafe = null;
                            try { accSafe = AccountRepository.getById(m.matchedId); } catch (Exception e) {}
                            if (accSafe != null) {
                                accName = accSafe.Name;
                                accIdForLink = accSafe.Id;
                            }
                        }
                        String link = '/lightning/r/Account/' + accIdForLink + '/view';
                        String percentStr = String.valueOf((m.matchIndex * 100).setScale(1)) + '%';
                        String display = String.isBlank(accName) ? ('Account ' + String.valueOf(accIdForLink)) : accName;

                        htmlWarnings.add('• <a href="' + link + '" target="_blank">' +
                                        StringNormalize.escapeHtml(display) + '</a> (match: ' + percentStr + ')<br/>');
                    }
                }
            }
            if (!matchResultsLead.isEmpty()) {
                htmlWarnings.add('\n\n');
                htmlWarnings.add('<strong>⚠️ Potential duplicates in Client Leads was found:</strong><br/>');
                for (Match m : matchResultsLead) {
                    if (m.matchIndex >= threshold) {
                        String leadName = m.matchedName;
                        Id leadIdForLink = m.matchedId;

                        if (String.isBlank(leadName)) {
                            ClientLead__c lSafe = null;
                            try { lSafe = LeadRepository.getById(m.matchedId); } catch (Exception e) {}
                            if (lSafe != null) {
                                leadName = lSafe.Name;
                                leadIdForLink = lSafe.Id;
                            }
                        }
                        String link = '/lightning/r/ClientLead__c/' + leadIdForLink + '/view';
                        String percentStr = String.valueOf((m.matchIndex * 100).setScale(1)) + '%';
                        String display = String.isBlank(leadName) ? ('Lead ' + String.valueOf(leadIdForLink)) : leadName;

                        htmlWarnings.add('• <a href="' + link + '" target="_blank">' +
                                        StringNormalize.escapeHtml(display) + '</a> (match: ' + percentStr + ')<br/>');
                    }
                }
            }
            if (htmlWarnings.size() > 1) {
                newlead.Duplicates__c = String.join(htmlWarnings, '');
            }

            // 4) Дефолти
            String Segment = '';
            String Division = '';
            String Manager = '';

            if(String.isBlank(newlead.BusinessDivision__c)) {
                newlead.BusinessDivision__c = currentUser.BusinesDivision__c;
                Division = SysUtils.getPicklistLabel(currentUser, 'BusinesDivision__c');
            } else {
                Division = newlead.BusinessDivision__c;
            }

            if(String.isBlank(newlead.MarketSegment__c)) {
                newlead.MarketSegment__c = currentUser.SalesDivision__c;
                Segment = SysUtils.getPicklistLabel(currentUser, 'SalesDivision__c');
            } else {
                Segment = getSegmName(newlead.MarketSegment__c);
            }

            if(String.isBlank(newlead.Manager__c)) {
                newlead.Manager__c = currentUser.Id;
                Manager = currentUser.Name;
            } else {
                Manager = UserRepository.getById(newlead.Manager__c).Name;
            }

            newlead.SalesSegm__c = 'Division: ' + Division.toUpperCase() + '\n'
                                 + 'Segment: ' + Segment.toUpperCase() + '\n'
                                 + 'Manager: ' + Manager.toUpperCase();

            // 5) Кладемо результати в кеш (щоб не рахувати вдруге в after)
            String key = makeKey(newlead);
            push(key, matchResultsAcc, matchResultsLead);
        }
    }

    public static void handleAfterInsert(List<ClientLead__c> newLeads) {
        Decimal threshold = 0.8;

        List<LeadDuplicateAcc__c>  dupAccInserts  = new List<LeadDuplicateAcc__c>();
        List<LeadDuplicateLead__c> dupLeadInserts = new List<LeadDuplicateLead__c>();

        for (ClientLead__c r : newLeads) {
            String key = makeKey(r);
            Pair pair = pop(key);

            for (Match m : pair.acc) {
                if (m.matchIndex >= threshold) {
                    LeadDuplicateAcc__c dup = new LeadDuplicateAcc__c();
                    dup.MainLead__c  = r.Id;          // lookup на створений лід
                    dup.DuplicateAcc__c     = m.matchedId;   // lookup на Account
                    dup.MatchIndex__c  = m.matchIndex;
                    dup.AccountNameIT__c  = r.Name;
                    dupAccInserts.add(dup);
                }
            }
            for (Match m : pair.lead) {
                if (m.matchIndex >= threshold) {
                    LeadDuplicateLead__c dupL = new LeadDuplicateLead__c();
                    dupL.MainLead__c     = r.Id;          // поточний лід
                    dupL.DuplicateLead__c  = m.matchedId;   // lookup на інший лід
                    dupL.MatchIndex__c     = m.matchIndex;
                    dupLeadInserts.add(dupL);
                }
            }
        }

        if(!dupAccInserts.isEmpty())  Database.insert(dupAccInserts,  false);
        if(!dupLeadInserts.isEmpty()) Database.insert(dupLeadInserts, false);
    }

    private static String getSegmName(String segmAPI) {
        switch on segmAPI {
            when '00001' { return 'AMERICA'; }
            when '00002' { return 'MENA'; }
            when '00004' { return 'EUROPE'; }
            when '00011' { return 'UKRAINE'; }
            when '00010' { return 'CIS'; }
            when '00006' { return 'KLW'; }
            when else    { return ''; }
        }
    }
}