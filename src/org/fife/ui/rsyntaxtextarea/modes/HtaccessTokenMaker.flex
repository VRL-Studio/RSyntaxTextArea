/*
 * 06/30/2013
 *
 * HtaccessTokenMaker.java - Token generator for .htaccess files.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * RSyntaxTextArea.License.txt file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for .htaccess files.
 *
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated HtaccessTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.7
 *
 */
%%

%public
%class HtaccessTokenMaker
%extends AbstractJFlexTokenMaker
%unicode
%ignorecase
%type org.fife.ui.rsyntaxtextarea.Token


%{

	/**
	 * Type specific to HtaccessTokenMaker denoting a line ending with an
	 * unclosed double-quote attribute.
	 */
	public static final int INTERNAL_ATTR_DOUBLE			= -1;


	/**
	 * Type specific to HtaccessTokenMaker denoting a line ending with an
	 * unclosed single-quote attribute.
	 */
	public static final int INTERNAL_ATTR_SINGLE			= -2;


	/**
	 * Token type specific to HtaccessTokenMaker denoting a line ending with an
	 * unclosed XML tag; thus a new line is beginning still inside of the tag.
	 */
	public static final int INTERNAL_INTAG					= -3;

	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public HtaccessTokenMaker() {
	}


	/**
	 * Adds the token specified to the current linked list of tokens as an
	 * "end token;" that is, at <code>zzMarkedPos</code>.
	 *
	 * @param tokenType The token's type.
	 */
	private void addEndToken(int tokenType) {
		addToken(zzMarkedPos,zzMarkedPos, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 * @see #addToken(int, int, int)
	 */
	private void addHyperlinkToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so, true);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *        occurs.
	 */
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * Returns how to transform a line into a line comment.
	 *
	 * @return The line comment start and end text for .htaccess files.
	 */
	public String[] getLineCommentStartAndEnd() {
		return new String[] { "#", null };
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state = YYINITIAL;
		switch (initialTokenType) {
			case INTERNAL_ATTR_DOUBLE:
				state = INATTR_DOUBLE;
				break;
			case INTERNAL_ATTR_SINGLE:
				state = INATTR_SINGLE;
				break;
			case INTERNAL_INTAG:
				state = INTAG;
				break;
			default:
				state = YYINITIAL;
		}

		start = text.offset;
		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new TokenImpl();
		}

	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 */
	private boolean zzRefill() {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(Reader reader) {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}

NameStartChar		= ([\:A-Z_a-z])
NameChar			= ({NameStartChar}|[\-\.0-9])
TagName				= ({NameStartChar}{NameChar}*)
Whitespace			= ([ \t\f]+)
Identifier			= ([^ \t\n<#]+)
InTagIdentifier		= ([^ \t\n\"\'=>]+)
LineCommentBegin	= ("#")

AnyCharacterButDoubleQuoteOrBackSlash	= ([^\\\"\n])
Escape									= ("\\".)
StringLiteral							= ([\"]({AnyCharacterButDoubleQuoteOrBackSlash}|{Escape})*[\"])
UnclosedStringLiteral					= ([\"]([\\].|[^\\\"])*[^\"]?)
ErrorStringLiteral						= ({UnclosedStringLiteral}[\"])

NameStartChar		= ([\:A-Z_a-z])
NameChar			= ({NameStartChar}|[\-\.0-9])
TagName				= ({NameStartChar}{NameChar}*)
DirectiveStart		= (("<"[/]?){TagName})

URLGenDelim				= ([:\/\?#\[\]@])
URLSubDelim				= ([\!\$&'\(\)\*\+,;=])
URLUnreserved			= ([A-Za-z_0-9\-\.\~])
URLCharacter			= ({URLGenDelim}|{URLSubDelim}|{URLUnreserved}|[%])
URLCharacters			= ({URLCharacter}*)
URLEndCharacter			= ([\/\$A-Za-z0-9])
URL						= (((https?|f(tp|ile))"://"|"www.")({URLCharacters}{URLEndCharacter})?)

%state EOL_COMMENT
%state INTAG
%state INATTR_DOUBLE
%state INATTR_SINGLE

%%

<YYINITIAL> {

	{Whitespace}				{ addToken(Token.WHITESPACE); }
	{LineCommentBegin}			{ start = zzMarkedPos-1; yybegin(EOL_COMMENT); }	
	
	"<"{TagName}				{
									int count = yylength();
									addToken(zzStartRead,zzStartRead, Token.MARKUP_TAG_DELIMITER);
									addToken(zzMarkedPos-(count-1), zzMarkedPos-1, Token.MARKUP_TAG_NAME);
									yybegin(INTAG);
								}
	"</"{TagName}				{
									int count = yylength();
									addToken(zzStartRead,zzStartRead+1, Token.MARKUP_TAG_DELIMITER);
									addToken(zzMarkedPos-(count-2), zzMarkedPos-1, Token.MARKUP_TAG_NAME);
									yybegin(INTAG);
								}
	
	"AcceptPathInfo" |
	"Action" |
	"AddAlt" |
	"AddAltByEncoding" |
	"AddAltByType" |
	"AddCharset" |
	"AddDefaultCharset" |
	"AddDescription" |
	"AddEncoding" |
	"AddHandler" |
	"AddIcon" |
	"AddIconByEncoding" |
	"AddIconByType" |
	"AddInputFilter" |
	"AddLanguage" |
	"AddOutputFilter" |
	"AddOutputFilterByType" |
	"AddType" |
	"Allow" |
	"Anonymous" |
	"Anonymous_Authoritative" |
	"Anonymous_LogEmail" |
	"Anonymous_MustGiveEmail" |
	"Anonymous_NoUserID" |
	"Anonymous_VerifyEmail" |
	"AuthAuthoritative" |
	"AuthBasicAuthoritative" |
	"AuthBasicProvider" |
	"AuthDBMAuthoritative" |
	"AuthDBMGroupFile" |
	"AuthDBMType" |
	"AuthDBMUserFile" |
	"AuthDigestAlgorithm" |
	"AuthDigestDomain" |
	"AuthDigestFile" |
	"AuthDigestGroupFile" |
	"AuthDigestNonceFormat" |
	"AuthDigestNonceLifetime" |
	"AuthDigestQop" |
	"AuthGroupFile" |
	"AuthLDAPAuthoritative" |
	"AuthLDAPBindDN" |
	"AuthLDAPBindPassword" |
	"AuthLDAPCompareDNOnServer" |
	"AuthLDAPDereferenceAliases" |
	"AuthLDAPEnabled" |
	"AuthLDAPFrontPageHack" |
	"AuthLDAPGroupAttribute" |
	"AuthLDAPGroupAttributeIsDN" |
	"AuthLDAPRemoteUserIsDN" |
	"AuthLDAPUrl" |
	"AuthName" |
	"AuthType" |
	"AuthUserFile" |
	"BrowserMatch" |
	"BrowserMatchNoCase" |
	"CGIMapExtension" |
	"CharsetDefault" |
	"CharsetOptions" |
	"CharsetSourceEnc" |
	"CheckSpelling" |
	"ContentDigest" |
	"CookieDomain" |
	"CookieExpires" |
	"CookieName" |
	"CookieStyle" |
	"CookieTracking" |
	"DefaultIcon" |
	"DefaultLanguage" |
	"DefaultType" |
	"Deny" |
	"DirectoryIndex" |
	"DirectorySlash" |
	"EnableMMAP" |
	"EnableSendfile" |
	"ErrorDocument" |
	"Example" |
	"ExpiresActive" |
	"ExpiresByType" |
	"ExpiresDefault" |
	"FileETag" |
	"ForceLanguagePriority" |
	"ForceType" |
	"Header" |
	"HeaderName" |
	"ImapBase" |
	"ImapDefault" |
	"ImapMenu" |
	"IndexIgnore" |
	"IndexOptions" |
	"IndexOrderDefault" |
	"ISAPIAppendLogToErrors" |
	"ISAPIAppendLogToQuery" |
	"ISAPIFakeAsync" |
	"ISAPILogNotSupported" |
	"ISAPIReadAheadBuffer" |
	"LanguagePriority" |
	"LimitRequestBody" |
	"LimitXMLRequestBody" |
	"MetaDir" |
	"MetaFiles" |
	"MetaSuffix" |
	"MultiviewsMatch" |
	"Options" |
	"Order" |
	"PassEnv" |
	"ReadmeName" |
	"Redirect" |
	"RedirectMatch" |
	"RedirectPermanent" |
	"RedirectTemp" |
	"RemoveCharset" |
	"RemoveEncoding" |
	"RemoveHandler" |
	"RemoveInputFilter" |
	"RemoveLanguage" |
	"RemoveOutputFilter" |
	"RemoveType" |
	"RequestHeader" |
	"Require" |
	"RewriteBase" |
	"RewriteCond" |
	"RewriteEngine" |
	"RewriteOptions" |
	"RewriteRule" |
	"RLimitCPU" |
	"RLimitMEM" |
	"RLimitNPROC" |
	"Satisfy" |
	"ScriptInterpreterSource" |
	"ServerSignature" |
	"SetEnv" |
	"SetEnvIf" |
	"SetEnvIfNoCase" |
	"SetHandler" |
	"SetInputFilter" |
	"SetOutputFilter" |
	"SSIErrorMsg" |
	"SSITimeFormat" |
	"SSLCipherSuite" |
	"SSLOptions" |
	"SSLProxyCipherSuite" |
	"SSLProxyVerify" |
	"SSLProxyVerifyDepth" |
	"SSLRequire" |
	"SSLRequireSSL" |
	"SSLUserName" |
	"SSLVerifyClient" |
	"SSLVerifyDepth" |
	"UnsetEnv" |
	"XBitHack"					{ addToken(Token.FUNCTION); }

	{Identifier}				{ addToken(Token.IDENTIFIER); }
	{StringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedStringLiteral}		{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{ErrorStringLiteral}		{ addToken(Token.ERROR_STRING_DOUBLE); }
	
	.							{ addToken(Token.IDENTIFIER); }
	\n |
	<<EOF>>						{ addNullToken(); return firstToken; }
}

<INTAG> {
	{InTagIdentifier}			{ addToken(Token.MARKUP_TAG_ATTRIBUTE); }
	{Whitespace}+				{ addToken(Token.WHITESPACE); }
	"="							{ addToken(Token.OPERATOR); }
	">"							{ yybegin(YYINITIAL); addToken(Token.MARKUP_TAG_DELIMITER); }
	[\"]						{ start = zzMarkedPos-1; yybegin(INATTR_DOUBLE); }
	[\']						{ start = zzMarkedPos-1; yybegin(INATTR_SINGLE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, INTERNAL_INTAG); return firstToken; }
}

<INATTR_DOUBLE> {
	[^\"]*						{}
	[\"]						{ yybegin(INTAG); addToken(start,zzStartRead, Token.MARKUP_TAG_ATTRIBUTE_VALUE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_TAG_ATTRIBUTE_VALUE); addEndToken(INTERNAL_ATTR_DOUBLE); return firstToken; }
}

<INATTR_SINGLE> {
	[^\']*						{}
	[\']						{ yybegin(INTAG); addToken(start,zzStartRead, Token.MARKUP_TAG_ATTRIBUTE_VALUE); }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.MARKUP_TAG_ATTRIBUTE_VALUE); addEndToken(INTERNAL_ATTR_SINGLE); return firstToken; }
}

<EOL_COMMENT> {
	[^hwf\n]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_EOL); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_EOL); start = zzMarkedPos; }
	[hwf]					{}
	\n |
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addNullToken(); return firstToken; }

}
