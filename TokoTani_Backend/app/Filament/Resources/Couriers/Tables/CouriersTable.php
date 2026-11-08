<?php

namespace App\Filament\Resources\Couriers\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class CouriersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->sortable(),
                TextColumn::make('nama')
                    ->label('Nama Kurir')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('tarif')
                    ->label('Tarif')
                    ->money('IDR', locale: 'id')
                    ->sortable(),
                IconColumn::make('aktif')
                    ->label('Status Aktif')
                    ->boolean()
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                TernaryFilter::make('aktif')
                    ->label('Status Aktif'),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make()
                    ->before(function (DeleteAction $action, \App\Models\Courier $record) {
                        if ($record->orders()->exists()) {
                            \Filament\Notifications\Notification::make()
                                ->title('Gagal Menghapus Kurir')
                                ->body("Kurir '{$record->nama}' memiliki riwayat pesanan. Anda dapat menonaktifkannya melalui toggle status aktif.")
                                ->warning()
                                ->send();

                            $action->halt();
                        }
                    }),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
