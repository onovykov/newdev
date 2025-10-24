@isTest
public class namesDuplicateSearchTest {

    // Тест для методу hasCommonWords
    @isTest
    public static void testHasCommonWords() {
        String name1 = 'Petroleum Pipe Company';
        String name2 = 'Petroleum Pipe Co Ltd';
        String name3 = 'Tech Solutions';

        Test.startTest();
        Boolean result1 = namesDuplicateSearch.hasCommonWords(name1, name2);
        Boolean result2 = namesDuplicateSearch.hasCommonWords(name1, name3);
        Test.stopTest();

        System.assert(result1 == true, 'Повинно повернути true для схожих назв');
        System.assert(result2 == false, 'Повинно повернути false для несхожих назв');
    }

    // Тест для методу countCommonWords
    @isTest
    public static void testCountCommonWords() {
        String name1 = 'Petroleum Pipe Company';
        String name2 = 'Petroleum Pipe Company Ltd';

        Test.startTest();
        Integer commonWordsCount = namesDuplicateSearch.countCommonWords(name1, name2);
        Test.stopTest();

        System.assertEquals(3, commonWordsCount, 'Повинно бути 3 спільних слова');
    }

    // Тест для методу countWordsInString
    @isTest
    public static void testCountWordsInString() {
        String name = 'Petroleum Pipe Company';

        Test.startTest();
        Integer wordCount = namesDuplicateSearch.countWordsInString(name);
        Test.stopTest();

        System.assertEquals(3, wordCount, 'Кількість слів має бути 3');
    }

    // Тест для методу levenshteinDistance
    @isTest
    public static void testLevenshteinDistance() {
        String name1 = 'Petroleum Pipe';
        String name2 = 'Petrolum Pip';

        Test.startTest();
        Integer distance = namesDuplicateSearch.levenshteinDistance(name1, name2);
        Test.stopTest();

        System.assertEquals(2, distance, 'Levenshtein Distance має бути 2');
    }

    // Тест для методу jaccardSimilarity
    @isTest
    public static void testJaccardSimilarity() {
        String name1 = 'Тест Дублів Назв';
        String name2 = 'Тест Дубльованих Назв ТОВ';

        Test.startTest();
        Double similarity = namesDuplicateSearch.jaccardSimilarity(name1, name2);
        Test.stopTest();

        System.assert(similarity >= 0.4 && similarity <= 0.5, 'Jaccard Similarity має бути в межах 0.4-0.5');
    }

    // Тест для методу soundex
    @isTest
    public static void testSoundex() {
        String name = 'Petroleum';

        Test.startTest();
        String soundexCode = namesDuplicateSearch.soundex(name);
        Test.stopTest();

        System.assertEquals('P000', soundexCode, 'Soundex код для "Petroleum" має бути P000');
    }

}