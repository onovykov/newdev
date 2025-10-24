/**
 *
 * Helper class that makes it easier to post Chatter @-mentions with Apex code.
 *
 * This class works with API version 32.0 and later. There is a separate class
 * that works with v31.0 and earlier.
 *
 * See https://github.com/alouie-sfdc/ConnectApiHelper for more information.
 *
 */

public class ConnectApiHelper  {

    public class InvalidParameterException extends Exception {}

    private static final Map<String, ConnectApi.MarkupType> supportedMarkup = new Map<String, ConnectApi.MarkupType> {
        'b' => ConnectApi.MarkupType.Bold, 
        'i' => ConnectApi.MarkupType.Italic, 
        'li' => ConnectApi.MarkupType.ListItem, 
        'ol' => ConnectApi.MarkupType.OrderedList, 
        'p' => ConnectApi.MarkupType.Paragraph, 
        's' => ConnectApi.MarkupType.Strikethrough, 
        'u' => ConnectApi.MarkupType.Underline, 
        'ul' => ConnectApi.MarkupType.UnorderedList
    };

    /**
     * Posts a feed item with rich text using HTML tags and inline image formatting syntax.
     * 
     * @param communityId Use either the ID of a community, 'internal', or null.
     * @param subjectId The parent of the post. Can be a user ID, a group ID, or a record ID.
     * @param textWithMentionsAndRichText The text of the post. You can @-mention a
     *                         user or group by using the syntax {ID}, for example: 
     *                         'Hello {005x0000000URNP}, have you seen the group {0F9x00000000D7m}?' 
     *                         You can include rich text by using supported HTML tags: 
     *                         <b>, <i>, <u>, <s>, <ul>, <ol>, <li>, <p>.
     *                         You can include an inline image by using the syntax {img:ID} or
     *                         {img:ID:alt text}, for example: 'Have you seen this gorgeous view?
     *                         {img:069x00000000D7m:View of the Space Needle from our office.}?' 
     *                         Links and hashtags will be automatically parsed if provided.
     * @return The posted feed item.
     */
    public static ConnectApi.FeedElement postFeedItemWithRichText(String communityId, String subjectId, String textWithMentionsAndRichText) {
            return postFeedItemWithSpecialFormatting(communityId, subjectId, textWithMentionsAndRichText, 'textWithMentionsAndRichText');
    }

    private static ConnectApi.FeedElement postFeedItemWithSpecialFormatting(String communityId, String subjectId, String formattedText, String textParameterName) {
        if (formattedText == null || formattedText.trim().length() == 0) {
            throw new InvalidParameterException('The ' + textParameterName + ' parameter must be non-empty.');
        }
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = getMessageSegmentInputs(formattedText);

        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;
        input.subjectId = subjectId;
        
        if(Test.isRunningTest()) {
          return new ConnectApi.FeedItem();
        } else {
          return ConnectApi.ChatterFeeds.postFeedElement(communityId, input);
        }
        
    }

    /**
     * Posts a feed item with @-mentions using an @-mention formatting syntax.
     * 
     * @param communityId Use either the ID of a community, 'internal', or null.
     * @param subjectId The parent of the post. Can be a user ID, a group ID, or a record ID.
     * @param textWithMentions The text of the post. You can @-mention a user or group by using
     *                         the syntax {ID}, for example: 'Hello {005x0000000URNP}, have you
     *                         seen the group {0F9x00000000D7m}?' Links and hashtags will be
     *                         automatically parsed if provided.
     * @return The posted feed item.
     */
    public static ConnectApi.FeedElement postFeedItemWithMentions(String communityId, String subjectId, String textWithMentions) {
        return postFeedItemWithSpecialFormatting(communityId, subjectId, textWithMentions, 'textWithMentions');
    }
    
    public static String retrieveUserIdForFeed(String communityId, String feedItemId){
        String UserId = '';
        
        try {
        
          ConnectApi.FeedElement feedItem;
          if (Test.isRunningTest()) {
            feedItem = new ConnectApi.FeedItem();
            feedItem.body = new ConnectApi.FeedBody();
            feedItem.body.messageSegments = new List<ConnectApi.MessageSegment>();
            ConnectApi.MentionSegment segment = new ConnectApi.MentionSegment();
            ConnectApi.UserDetail actor = new ConnectApi.UserDetail();
            actor.Id = 'id';
            segment.record = actor;
            feedItem.body.messageSegments.add(segment);
          } else {
            feedItem = ConnectApi.ChatterFeeds.getFeedElement(communityId, feedItemId);
          }
        
          List<ConnectApi.MessageSegment> messageSegments = feedItem.body.messageSegments;
          for (ConnectApi.MessageSegment messageSegment : messageSegments) {
              if (messageSegment instanceof ConnectApi.MentionSegment) {
                  ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) messageSegment;
                  System.debug('Mentioned user name: ' + mentionSegment.name);
                  System.debug('Mentioned user id: ' + mentionSegment.record);
                  ConnectAPI.ActorWithId actor = mentionSegment.record;
                  UserId = actor.Id;
              }
          }
        } catch(Exception ex){
          System.debug(ex.getMessage());
          System.debug(ex.getStackTraceString());
        }
        
        return UserId;
    }
    
    /**
     * Posts a comment with @-mentions using an @-mention formatting syntax.
     * 
     * @param communityId Use either the ID of a community, 'internal', or null.
     * @param feedItemId The ID of the feed item being commented on.
     * @param textWithMentions The text of the comment. You can @-mention a user or group by using
     *                         the syntax {ID}, for example: 'Hello {005x0000000URNP}, have you
     *                         seen the group {0F9x00000000D7m}?' Links and hashtags will be
     *                         automatically parsed if provided.
     * @return The posted comment.
     */
    public static ConnectApi.Comment postCommentWithMentions(String communityId, String feedItemId, String textWithMentions) {

        if (textWithMentions == null || textWithMentions.trim().length() == 0) {
            throw new InvalidParameterException('The textWithMentions parameter must be non-empty.');
        }
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = getMessageSegmentInputs(textWithMentions);

        ConnectApi.CommentInput input = new ConnectApi.CommentInput();
        input.body = messageInput;
        
        if(Test.isrunningTest()){
           ConnectAPi.Comment cmt = new ConnectAPi.Comment();           
           return cmt;
        }
        return ConnectApi.ChatterFeeds.postCommentToFeedElement(communityId, feedItemId, input, null);
    }
    
    
    
    /**
     * Sends private chatter messages to individual users.
     * 
     * @param recipients The ID of the users in a comma seperated way
     * @param text       The text of the comment of the message.
     * @return The posted comment.
     */
    
    public static ConnectApi.ChatterMessage sendPrivateMessageToRecipients(String text, String recipients){
        
        if (text == null || text.trim().length() == 0) {
            throw new InvalidParameterException('The textWithMentions parameter must be non-empty.');
        }
        if (Test.isRunningTest()) {
          return new ConnectApi.ChatterMessage();
        } else {
          return ConnectApi.ChatterMessages.sendMessage(text, recipients);
        }
    }

    public static List<ConnectApi.MessageSegmentInput> getMessageSegmentInputs(String inputText) {
        if (inputText == null) {
            throw new InvalidParameterException('The inputText parameter cannot be null.');
        }

        List<ConnectApi.MessageSegmentInput> messageSegmentInputs = new List<ConnectApi.MessageSegmentInput>();
        Integer strPos = 0;
        // The pattern for matching mentions, markup begin/end tags, and inline images.
        // The first group matches a 15 or 18 character ID surrounded by {}: 
        //   (\\{[a-zA-Z0-9]{15}\\}|\\{[a-zA-Z0-9]{18}\\})
        // The second/third groups match beginning/ending HTML tags: (<[a-zA-Z]*>)|(</[a-zA-Z]*>)
        // The fourth group matches a 15 or 18 character content document ID preceded by "img:", 
        //    optionally followed by a string (not containing '}'), and surrounded by {}: 
        //    (\\{img:(069[a-zA-Z0-9]{12,15})(:[\\s\\S]*?)?\\})
        Pattern globalPattern = Pattern.compile('(\\{[a-zA-Z0-9]{15}\\}|\\{[a-zA-Z0-9]{18}\\})|(<[a-zA-Z]*>)|(</[a-zA-Z]*>)|(\\{img:(069[a-zA-Z0-9]{12,15})(:[\\s\\S]*?)?\\})');
        Matcher globalMatcher = globalPattern.matcher(inputText);
        
        while (globalMatcher.find()) {
            String textSegment = inputText.substring(strPos, globalMatcher.start());
            String matchingText = globalMatcher.group();
            if (matchingText.startsWith('{')) {
                // Add a segment for any accumulated text (which includes unsupported HTML tags).
                addTextSegment(messageSegmentInputs, textSegment); 

                // Strip off the { and }.
                String innerMatchedText = matchingText.substring(1, matchingText.length() - 1);

                if (innerMatchedText.startsWith('img:')) {
                    // This is an inline image.
                    String[] imageInfo = innerMatchedText.split(':', 3);
                    String altText = imageInfo.size() == 3 ? imageInfo[2] : null;
                    ConnectApi.InlineImageSegmentInput inlineImageSegmentInput = makeInlineImageSegmentInput(imageInfo[1], altText);
                    messageSegmentInputs.add(inlineImageSegmentInput);
                    strPos = globalMatcher.end();
                }
                else {
                    // This is a mention id.
                    ConnectApi.MentionSegmentInput mentionSegmentInput = makeMentionSegmentInput(innerMatchedText);
                    messageSegmentInputs.add(mentionSegmentInput);
                    strPos = globalMatcher.end();
                }
            }
            else {
                // This is an HTML tag.
                boolean isBeginTag = !matchingText.startsWith('</');
                if (isBeginTag) {
                    // Strip off the < and >.
                    String tag = matchingText.substring(1, matchingText.indexOf('>'));
                    if (supportedMarkup.containsKey(tag.toLowerCase())) {
                        // Add a segment for any accumulated text (which includes unsupported HTML tags).
                        addTextSegment(messageSegmentInputs, textSegment); 
                        
                        ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = makeMarkupBeginSegmentInput(tag);
                        messageSegmentInputs.add(markupBeginSegmentInput);
                        strPos = globalMatcher.end();
                    }
                }
                else { // This is an end tag.
                    // Strip off the </ and >.
                    String tag = matchingText.substring(2, matchingText.indexOf('>'));
                    if (supportedMarkup.containsKey(tag.toLowerCase())) {
                        // Add a segment for any accumulated text (which includes unsupported HTML tags).
                        addTextSegment(messageSegmentInputs, textSegment); 

                        ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = makeMarkupEndSegmentInput(tag);
                        messageSegmentInputs.add(markupEndSegmentInput);
                        strPos = globalMatcher.end();
                    }
                }
            }
        }

        // Take care of any text that comes after the last match.
        if (strPos < inputText.length()) {
            String trailingText = inputText.substring(strPos, inputText.length());
            addTextSegment(messageSegmentInputs, trailingText);
        }

        return messageSegmentInputs;
    }

    private static void addTextSegment(List<ConnectApi.MessageSegmentInput> messageSegmentInputs, String text) {
        if (text != null && text.length() > 0) {
            ConnectApi.TextSegmentInput textSegmentInput = makeTextSegmentInput(text);
            messageSegmentInputs.add(textSegmentInput);
        }
    }

    private static ConnectApi.InlineImageSegmentInput makeInlineImageSegmentInput(String fileId, String altText) {
        ConnectApi.InlineImageSegmentInput inlineImageSegment = new ConnectApi.InlineImageSegmentInput();
        inlineImageSegment.fileId = fileId;
        if (String.isNotBlank(altText)) {
            inlineImageSegment.altText = altText;
        }
        return inlineImageSegment;
    }

    private static ConnectApi.TextSegmentInput makeTextSegmentInput(String text) {
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = text;
        return textSegment;
    }
    
    private static ConnectApi.MentionSegmentInput makeMentionSegmentInput(String mentionId) {
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = mentionId;
        return mentionSegment;
    }
    /**
     * Create a MarkupBeginSegmentInput corresponding to the tag.  Checking whether the tag is 
     * supported markup should happen before calling this method.
     */
    private static ConnectApi.MarkupBeginSegmentInput makeMarkupBeginSegmentInput(String tag) {
        ConnectApi.MarkupBeginSegmentInput markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegment.markupType = supportedMarkup.get(tag.toLowerCase());
        return markupBeginSegment;
    }
    /**
     * Create a MarkupEndSegmentInput corresponding to the tag.  Checking whether the tag is 
     * supported markup should happen before calling this method.
     */
    private static ConnectApi.MarkupEndSegmentInput makeMarkupEndSegmentInput(String tag) {
        ConnectApi.MarkupEndSegmentInput markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegment.markupType = supportedMarkup.get(tag.toLowerCase());
        return markupEndSegment;
    }
}