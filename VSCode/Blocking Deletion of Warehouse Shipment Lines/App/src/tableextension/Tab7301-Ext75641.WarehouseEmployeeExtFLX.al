tableextension 75641 "WarehouseEmployeeExtFLX" extends "Warehouse Employee" //7301
{
    fields
    {
        field(75640; "Allowed to Delete Shpt. Line"; Boolean)
        {
            Caption = 'Allowed to Delete Whse. Shpt. Line';
            DataClassification = ToBeClassified;
        }
    }

    procedure CheckAllowedToDeleteWhsShipmentLine(): Boolean
    var
        WarehouseSetup: Record "Warehouse Setup";
        NotAlllowedToDeleteSystemCreatedLinesErr: Label 'You are not allowed to delete system-created warehouse shipment lines on current location.';
        DeleteThisSystemCreatedLineMsg: Label 'Are you sure you want to delete this system-created line?';
    begin
        WarehouseSetup.Get();

        if not WarehouseSetup."Unblock Deletion of Shpt. Line" then
            Error(NotAlllowedToDeleteSystemCreatedLinesErr)
        else begin
            if not "Allowed to Delete Shpt. Line" then
                Error(NotAlllowedToDeleteSystemCreatedLinesErr);

            if Confirm(DeleteThisSystemCreatedLineMsg, false) = false then
                Error('');
        end;
    end;
}