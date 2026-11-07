<?php

namespace App\Filament\Resources\PaymentMethods\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class PaymentMethodsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')->sortable(),
                TextColumn::make('nama')
                    ->label('Nama Metode')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('deskripsi')
                    ->label('Deskripsi')
                    ->limit(50),
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
                    ->before(function (DeleteAction $action, \App\Models\PaymentMethod $record) {
                        if ($record->orders()->exists()) {
                            \Filament\Notifications\Notification::make()
                                ->title('Gagal Menghapus')
                                ->body("Metode pembayaran '{$record->nama}' memiliki riwayat pesanan. Anda dapat menonaktifkannya melalui toggle status aktif.")
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
