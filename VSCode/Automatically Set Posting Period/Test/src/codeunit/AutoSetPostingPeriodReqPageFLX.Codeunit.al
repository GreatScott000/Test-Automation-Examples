codeunit 80465 "AutoSetPostingPeriodReqPageFLX"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] Request Page
    end;

    [Test]
    [HandlerFunctions('UpdateAllowPostingFLXRequestPageHandler')]
    procedure SetStartingDateAndEndingDateForCurrentPeriod()
    // [FEATURE] Request Page
    var
        RequestPageXml: Text;
    begin
        // [SCENARIO #0001] Set "Starting Date"  and "Ending Date" for current period
        Initialize();

        // [GIVEN] Accounting periods for current fiscal year related to system date
        CreateAccountingPeriodsForCurrentFiscalYearRelatedToSystemDate();
        // [GIVEN] Accounting periods for next fiscal year related to system date
        CreateAccountingPeriodsForNextFiscalYearRelatedToSystemDate();

        // [WHEN] Disable "Use Next Period" on Request Page
        RequestPageXml := DisableUseNextPeriodOnRequestPage();

        // [THEN] "Current Accounting Period" equals start date of current accounting period
        VerifyCurrentAccountingPeriodEqualsStartDateOfCurrentAccountingPeriod(RequestPageXml);
        // [THEN] "Starting Date" equals first date of current accounting period
        VerifyStartingDateEqualsFirstDateOfCurrentAccountingPeriod(RequestPageXml);
        // [THEN] "Ending Date" equals first date of next accounting period minus one day
        VerifyEndingDateEqualsFirstDateOfNextAccountingPeriodMinusOneDay(RequestPageXml);
    end;

    [Test]
    [HandlerFunctions('UpdateAllowPostingFLXRequestPageHandler')]
    procedure SetStartingDateAndEndingDateForNextPeriod()
    // [FEATURE] Request Page
    var
        RequestPageXml: Text;
    begin
        // [SCENARIO #0002] Set "Starting Date"  and "Ending Date" for next period
        Initialize();

        // [GIVEN] Accounting periods for current fiscal year related to system date
        CreateAccountingPeriodsForCurrentFiscalYearRelatedToSystemDate();
        // [GIVEN] Accounting periods for next fiscal year related to system date
        CreateAccountingPeriodsForNextFiscalYearRelatedToSystemDate();

        // [WHEN] Enable "Use Next Period" on Request Page
        RequestPageXml := EnableUseNextPeriodOnRequestPage();

        // [THEN] "Current Accounting Period" equals start date of current accounting period
        VerifyCurrentAccountingPeriodEqualsStartDateOfCurrentAccountingPeriod(RequestPageXml);
        // [THEN] "Starting Date" equals first date of next accounting period
        VerifyStartingDateEqualsFirstDateOfNextAccountingPeriod(RequestPageXml);
        // [THEN] "Ending Date" equals first date of accounting period after next account period minus one day
        VerifyEndingDateEqualsFirstDateOfAccountingPeriodAfterNextAccountPeriodMinusOneDay(RequestPageXml);
    end;

    [Test]
    [HandlerFunctions('UpdateAllowPostingFLXRequestPageHandler')]
    procedure SetStartingDateAndEndingDateForNonExistingNextAccountingPeriod()
    // [FEATURE] Request Page
    var
        RequestPageXml: Text;
    begin
        // [SCENARIO #0003] Set "Starting Date" and "Ending Date" for non-existing next accounting period
        Initialize();

        // [GIVEN] No next accounting period related to system date
        CreateNoNextAccountingPeriodRelatedToSystemDate();

        // [WHEN] Open request page
        RequestPageXml := OpenRequestPage();

        // [THEN] Error on non-existing next accounting period
        VerifyErrorOnNonExistingNextAccountingPeriod(RequestPageXml);
    end;

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::AutoSetPostingPeriodReqPageFLX);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::AutoSetPostingPeriodReqPageFLX);
        DeleteAllAccountingPeriods();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::AutoSetPostingPeriodReqPageFLX);
    end;

    local procedure CreateAccountingPeriodsForCurrentFiscalYearRelatedToSystemDate()
    begin
        LibraryAutoSetPostPeriodFLX.CreateFiscalYearForDate(Today);
    end;

    local procedure CreateAccountingPeriodsForNextFiscalYearRelatedToSystemDate()
    begin
        LibraryAutoSetPostPeriodFLX.CreateFiscalYearForDate(CalcDate('<+1Y>', Today));
    end;

    local procedure CreateNoNextAccountingPeriodRelatedToSystemDate()
    begin
        CreateAccountingPeriodsForCurrentFiscalYearRelatedToSystemDate();
        DeleteAccountingPeriodsAfterDate(Today);
    end;

    local procedure DisableUseNextPeriodOnRequestPage(): Text;
    var
        UpdateAllowPostingFLX: Report UpdateAllowPostingFLX;
    begin
        Commit(); //Write transactions happened, so commit
        LibraryVariableStorage.Enqueue(DoNotUseNextPeriodOnRequestPage());
        exit(UpdateAllowPostingFLX.RunRequestPage());
    end;

    local procedure EnableUseNextPeriodOnRequestPage(): Text;
    var
        UpdateAllowPostingFLX: Report UpdateAllowPostingFLX;
    begin
        Commit(); //Write transactions happened, so commit
        LibraryVariableStorage.Enqueue(UseNextPeriodOnRequestPage());
        exit(UpdateAllowPostingFLX.RunRequestPage());
    end;

    local procedure OpenRequestPage() RequestPageXml: Text;
    var
        UpdateAllowPostingFLX: Report UpdateAllowPostingFLX;
    begin
        LibraryVariableStorage.Enqueue(DoNotUseNextPeriodOnRequestPage());
        asserterror RequestPageXml := UpdateAllowPostingFLX.RunRequestPage();
    end;

    local procedure VerifyCurrentAccountingPeriodEqualsStartDateOfCurrentAccountingPeriod(RequestPageXml: Text)
    var
        RequestPageFieldValue: Text;
        CurrAccPeriodDateOnReqPage: Date;
    begin
        CurrAccPeriodDateOnReqPage := LibraryAutoSetPostPeriodFLX.GetDateValueFromRequestPage(RequestPageXml, CurrPeriodStartingDateXmlElement());
        Assert.AreEqual(CurrAccPeriodDateOnReqPage, LibraryAutoSetPostPeriodFLX.GetAccountingPeriodStartForDate(Today), CurrAccPeriodDateOnReqPageCaptionTxt);
    end;

    local procedure VerifyEndingDateEqualsFirstDateOfAccountingPeriodAfterNextAccountPeriodMinusOneDay(RequestPageXml: Text)
    var
        RequestPageFieldValue: Text;
        PeriodEndDateOnReqPage: Date;
    begin
        PeriodEndDateOnReqPage := LibraryAutoSetPostPeriodFLX.GetDateValueFromRequestPage(RequestPageXml, PeriodEndingDateXmlElement());
        Assert.AreEqual(PeriodEndDateOnReqPage,
            LibraryAutoSetPostPeriodFLX.GetNextAccountingPeriodEndForDate(Today), PeriodEndingDateOnReqPageCaptionTxt);
    end;

    local procedure VerifyEndingDateEqualsFirstDateOfNextAccountingPeriodMinusOneDay(RequestPageXml: Text)
    var
        RequestPageFieldValue: Text;
        PeriodEndDateOnReqPage: Date;
    begin
        PeriodEndDateOnReqPage := LibraryAutoSetPostPeriodFLX.GetDateValueFromRequestPage(RequestPageXml, PeriodEndingDateXmlElement());
        Assert.AreEqual(PeriodEndDateOnReqPage, LibraryAutoSetPostPeriodFLX.GetAccountingPeriodEndForDate(Today), PeriodEndingDateOnReqPageCaptionTxt);
    end;

    local procedure VerifyErrorOnNonExistingNextAccountingPeriod(RequestPageXml: Text)
    var
        UpdateAllowPostingFLX: Report UpdateAllowPostingFLX;
    begin
        LibraryVariableStorage.Enqueue(UseNextPeriodOnRequestPage());
        asserterror RequestPageXml := UpdateAllowPostingFLX.RunRequestPage(RequestPageXml);
    end;

    local procedure VerifyStartingDateEqualsFirstDateOfCurrentAccountingPeriod(RequestPageXml: Text)
    var
        RequestPageFieldValue: Text;
        PeriodStartDateOnReqPage: Date;
    begin
        PeriodStartDateOnReqPage := LibraryAutoSetPostPeriodFLX.GetDateValueFromRequestPage(RequestPageXml, PeriodStartingDateXmlElement());
        Assert.AreEqual(PeriodStartDateOnReqPage, LibraryAutoSetPostPeriodFLX.GetAccountingPeriodStartForDate(Today), PeriodStartingDateOnReqPageCaptionTxt);
    end;

    local procedure VerifyStartingDateEqualsFirstDateOfNextAccountingPeriod(RequestPageXml: Text)
    var
        RequestPageFieldValue: Text;
        PeriodStartDateOnReqPage: Date;
    begin
        PeriodStartDateOnReqPage := LibraryAutoSetPostPeriodFLX.GetDateValueFromRequestPage(RequestPageXml, PeriodStartingDateXmlElement());
        Assert.AreEqual(PeriodStartDateOnReqPage, LibraryAutoSetPostPeriodFLX.GetNextAccountingPeriodStartForDate(Today), PeriodStartingDateOnReqPageCaptionTxt);
    end;

    local procedure DeleteAllAccountingPeriods();
    begin
        LibraryAutoSetPostPeriodFLX.DeleteAccountingPeriodsFromDate(0D);
    end;

    local procedure DeleteAccountingPeriodsAfterDate(BaseDate: Date);
    begin
        LibraryAutoSetPostPeriodFLX.DeleteAccountingPeriodsFromDate(BaseDate);
    end;

    local procedure UseNextPeriodOnRequestPage(): Boolean;
    begin
        exit(true);
    end;

    local procedure DoNotUseNextPeriodOnRequestPage(): Boolean;
    begin
        exit(false);
    end;

    local procedure PeriodStartingDateXmlElement(): Text;
    begin
        exit('PeriodStartingDate');
    end;

    local procedure PeriodEndingDateXmlElement(): Text;
    begin
        exit('PeriodEndingDate');
    end;

    local procedure CurrPeriodStartingDateXmlElement(): Text;
    begin
        exit('CurrPeriodStartingDate');
    end;

    [RequestPageHandler]
    procedure UpdateAllowPostingFLXRequestPageHandler(var UpdateAllowPostingFLXRequestPage: TestRequestPage UpdateAllowPostingFLX);
    begin
        UpdateAllowPostingFLXRequestPage.UseNextPeriod.SetValue(LibraryVariableStorage.DequeueBoolean());
        UpdateAllowPostingFLXRequestPage.Ok.Invoke();
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryAutoSetPostPeriodFLX: Codeunit LibraryAutoSetPostPeriodFLX;
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        CurrAccPeriodDateOnReqPageCaptionTxt: Label 'Current Account Period Date';
        PeriodStartingDateOnReqPageCaptionTxt: Label 'Period Starting Date';
        PeriodEndingDateOnReqPageCaptionTxt: Label 'Period Ending Date';
}